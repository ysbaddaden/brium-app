require "gobject/gtk"
require "./message"
require "./brium_client"

module BriumApp
  class Application < Gtk::Application
    enum ActionType
      AddToChat
    end
    alias ActionData = Message

    @pending_mutex = Thread::Mutex.new
    @pending_ui_actions = Deque({ActionType, ActionData}).new

    @messages = [] of Message

    # we must keep references to every GObject we create and are still present
    # on the UI, otherwise the GC will collect them, and the GTK application
    # will start crashing or exiting unexpectedly

    # TODO: extract the actual window to its own class, maybe even a pair of
    #       classes: one with the UI and another with the logic.

    # TODO: when access token isn't defined, present a window to request and
    #       enter the access token, then close it and present the talk UI.

    @window : Gtk::ApplicationWindow?
    @vbox : Gtk::Box?
    @chat_bottom_mark : Gtk::TextMark?
    @chat_view : Gtk::TextView?
    @chat_view_scroll : Gtk::ScrolledWindow?
    @chat_entry : Gtk::Entry?

    def initialize
      super application_id: "me.brium.app"

      on_activate do
        render_chat_window
      end
    end

    private def render_chat_window : Nil
      window.connect("destroy") { quit }

      chat_view_scroll.add(chat_view)
      vbox.add(chat_view_scroll)
      vbox.add(chat_entry)

      window.add(vbox)
      window.show_all

      chat_entry.on_activate { handle_chat_message }
      chat_entry.placeholder_text = "Write your message..."
      chat_entry.grab_focus_without_selecting
    end

    private def handle_chat_message
      log = chat_entry.text.strip

      unless log.empty?
        add_to_chat(Message.new(:sent, log))
        spawn { send_to_brium(log) }
      end
    end

    private def add_to_chat(message : Message) : Nil
      @messages << message
      append_message_to_chat(message)
      scroll_chat_to_bottom
      clear_chat_entry
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

      update_ui_from_mt(:add_to_chat, message)
    end

    # When running in a fiber which runs on another thread than the main GTK
    # thread (because GTK blocks the main thread). We must queue a callback that
    # GTK will eventually run on the main thread (during idle time) in order to
    # update the UI.
    protected def update_ui_from_mt(action : ActionType, data : ActionData)
      @pending_mutex.synchronize { @pending_ui_actions << {action, data} }

      GC.collect

      GLib.idle_add(0, ->(data : Void*) {
        data.unsafe_as(Application).process_pending_ui_update
        0 # run once
      }, self.unsafe_as(Pointer(Void)), nil)
    end

    # :nodoc:
    def process_pending_ui_update : Nil
      if msg = @pending_mutex.synchronize { @pending_ui_actions.shift? }
        action, data = msg

        case action
        in .add_to_chat?
          add_to_chat(data.as(Message))
        end
      end
    end

    private def append_message_to_chat(message : Message) : Nil
      markup = message.to_pango_s
      buffer = chat_view.buffer
      buffer.insert_markup(chat_end_iter, markup, markup.bytesize)
      buffer.insert(chat_end_iter, "\n\n", "\n\n".bytesize)
    end

    private def scroll_chat_to_bottom : Nil
      chat_view.buffer.move_mark(chat_bottom_mark, chat_end_iter)
      chat_view.scroll_to_mark(chat_bottom_mark, 0.0, false, 0.0, 0.0)
    end

    private def clear_chat_entry : Nil
      chat_entry.text = ""
    end

    private def window : Gtk::ApplicationWindow
      @window ||= Gtk::ApplicationWindow.new(
        application: self,
        title: "Brium",
        default_width: 300,
        default_height: 400,
      )
    end

    private def vbox : Gtk::Box
      @vbox ||= Gtk::Box.new(orientation: :vertical)
    end

    private def chat_entry : Gtk::Entry
      @chat_entry ||= Gtk::Entry.new(margin: 4)
    end

    private def chat_view : Gtk::TextView
      @chat_view ||= Gtk::TextView.new(
        editable: false,
        cursor_visible: false,
        border_width: 4,
        wrap_mode: :word_char
      )
    end

    private def chat_bottom_mark : Gtk::TextMark
      @chat_bottom_mark ||= chat_view.buffer.create_mark("chat_bottom_mark", chat_end_iter, false)
    end

    private def chat_end_iter : Gtk::TextIter
      iter = Gtk::TextIter.new
      chat_view.buffer.end_iter(iter)
      iter
    end

    private def chat_view_scroll : Gtk::ScrolledWindow
      @chat_view_scroll ||= Gtk::ScrolledWindow.new(hexpand: false, vexpand: true)
    end
  end
end
