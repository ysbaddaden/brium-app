module BriumApp
  class Application < Gtk::Application
    @messages = [] of Message
    @window : Window?
    @activated = false

    def initialize
      super application_id: "me.brium.app"

      on_activate do
        if @activated
          window.present_with_time(Time.utc.to_unix)
        else
          @activated = true
          window.build
          window.connect("destroy") { quit }
          window.chat_entry.on_activate { handle_chat_message }
        end
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

      # When running in a fiber which runs on another thread than the main GTK
      # thread (because GTK blocks the main thread). We must queue a callback that
      # GTK will eventually run on the main thread (during idle time) in order to
      # update the UI.
      GLib.idle_add do
        window.add_to_chat(message)
        false
      end
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
