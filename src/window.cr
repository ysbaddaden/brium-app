module BriumApp
  class Window < Gtk::ApplicationWindow
    # We must keep references to every GObject we create and are still present
    # on the UI, otherwise the GC will collect them, and the GTK application
    # will start crashing or exiting unexpectedly!

    @headerbar : Gtk::HeaderBar?
    @vbox : Gtk::Box?
    @chat_bottom_mark : Gtk::TextMark?
    @chat_view : Gtk::TextView?
    @chat_view_scroll : Gtk::ScrolledWindow?
    @chat_entry : Gtk::Entry?

    def build : Nil
      self.titlebar = headerbar

      chat_view_scroll.add(chat_view)
      vbox.add(chat_view_scroll)

      chat_entry.placeholder_text = "Write your message..."
      vbox.add(chat_entry)

      add(vbox)
      show_all

      chat_entry.grab_focus_without_selecting
    end

    def add_to_chat(message : Message) : Nil
      append_message_to_chat(message)
      scroll_chat_to_bottom
      clear_chat_entry
    end

    def append_message_to_chat(message : Message) : Nil
      markup = message.to_pango_s
      buffer = chat_view.buffer
      buffer.insert_markup(chat_end_iter, markup, markup.bytesize)
      buffer.insert(chat_end_iter, "\n\n", "\n\n".bytesize)
    end

    def scroll_chat_to_bottom : Nil
      chat_view.buffer.move_mark(chat_bottom_mark, chat_end_iter)
      chat_view.scroll_to_mark(chat_bottom_mark, 0.0, false, 0.0, 0.0)
    end

    def clear_chat_entry : Nil
      chat_entry.text = ""
    end

    private def headerbar : Gtk::HeaderBar
      @headerbar ||= Gtk::HeaderBar.new(
        title: "Brium",
        subtitle: "Talk",
        show_close_button: true
      )
    end

    private def vbox : Gtk::Box
      @vbox ||= Gtk::Box.new(orientation: :vertical)
    end

    def chat_entry : Gtk::Entry
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