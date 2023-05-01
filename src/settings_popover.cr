module BriumApp
  class SettingsPopover < Gtk::Popover
    @access_token_label : Gtk::Label?
    @origin_label : Gtk::Label?

    def initialize(@window : Window)
      super()

      vbox.add(access_token_label)
      vbox.add(access_token_entry)

      {% unless flag?(:release) %}
        vbox.add(origin_label)
        vbox.add(origin_entry)
      {% end %}

      vbox.add(submit_button)

      vbox.show_all
      add(vbox)

      connect("show") { origin_entry.text = Settings.origin }
      connect("closed") { access_token_entry.text = "" }
      submit_button.connect("clicked") { save_settings }
    end

    private def save_settings : Nil
      Settings.origin = origin_entry.text.presence

      if token = access_token_entry.text.presence
        Settings.access_token = token
      end

      if Settings.configured?
        Settings.write_settings
        @window.close_settings
      end
    end

    private def vbox : Gtk::Box
      @vbox ||= Gtk::Box.new(
        orientation: :vertical,
        border_width: 10,
        spacing: 10,
      )
    end

    private def access_token_label
      @access_token_label ||= Gtk::Label.new(
        label: "Access token",
        halign: :start,
      )
    end

    private def access_token_entry
      @access_token_entry ||= Gtk::Entry.new
    end

    private def origin_label
      @origin_label ||= Gtk::Label.new(
        label: "Origin",
        halign: :start,
      )
    end

    private def origin_entry
      @origin_entry ||= Gtk::Entry.new(
        placeholder_text: Settings::DEFAULT_ORIGIN,
      )
    end

    private def submit_button
      @submit_button ||= Gtk::Button.new_with_label("Save")
    end
  end
end
