require "http"

module BriumApp
  class BriumClient
    INSTANCE = new(access_token, origin)

    def self.messages(log : String) : {Symbol, String}
      INSTANCE.messages(log)
    end

    def self.origin : String
      ENV.fetch("BRIUM_ORIGIN", "https://brium.me")
    end

    def self.access_token : String
      ENV.fetch("BRIUM_ACCESS_TOKEN") do
        path = config_path("access_token")

        if File.exists?(path)
          File.read(path).strip
        else
          raise "TODO: create a Gtk::Window to ask user for an API access token"
        end
      end
    end

    def self.config_path(filename : String) : Path
      {% if flag?(:windows) %}
        Path["~/AppData/Local/brium", filename].expand(home: true)
      {% else %}
        Path[ENV.fetch("XDG_CONFIG_HOME", "~/.config"), "brium", filename].expand(home: true)
      {% end %}
    end

    protected def initialize(access_token : String, @origin : String)
      @headers = HTTP::Headers{"Authorization" => "Bearer #{access_token}"}
    end

    def messages(log : String) : {Symbol, String}
      url = "#{@origin}/api/messages"
      response = HTTP::Client.post(url, headers: @headers, body: log)

      if response.success?
        {:success, response.body}
      else
        {:error, response.body? || ""}
      end
    end
  end
end
