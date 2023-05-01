module BriumApp
  # TODO: when access token isn't defined, present a window to request and
  #       enter the access token, then close it and present the talk UI.

  class Application < Gtk::Application
    @pending_mutex = Thread::Mutex.new
    @pending_callbacks = Deque(->).new

    @messages = [] of Message

    @window : Window?

    def initialize
      super application_id: "me.brium.app"

      on_activate do
        window.build
        window.connect("destroy") { quit }
        window.chat_entry.on_activate { handle_chat_message }
      end
    end

    private def handle_chat_message
      log = window.chat_entry.text.strip

      unless log.empty?
        message = Message.new(:sent, log)
        @messages << message
        window.add_to_chat(message)
        spawn { send_to_brium(log) }
      end
    end

    private def send_to_brium(log : String) : Nil
      result, reply = BriumClient.messages(log)

      message =
        case result
        when :success
          Message.new(:received, reply.strip)
        when :error
          Message.new(:failed, reply.strip)
        else
          raise "unreachable"
        end
      @messages << message

      idle_add do
        window.add_to_chat(message)
      end
    end

    # When running in a fiber which runs on another thread than the main GTK
    # thread (because GTK blocks the main thread). We must queue a callback that
    # GTK will eventually run on the main thread (during idle time) in order to
    # update the UI.
    private def idle_add(&callback : ->)
      @pending_mutex.synchronize { @pending_callbacks << callback }

      GLib.idle_add(0, ->(data : Void*) {
        app = data.as(Application)
        cb = app.@pending_mutex.synchronize { app.@pending_callbacks.shift? }
        cb.try(&.call)
        0
      }, self.as(Void*), nil)
    end

    private def window : Window
      @window ||= Window.new(
        application: self,
        title: "Brium",
        default_width: 300,
        default_height: 400,
      )
    end
  end
end
