require "http"

module BriumApp
  module BriumClient
    def self.messages(log : String) : {Symbol, String}
      response = post("/api/messages", body: log)

      if response.success?
        {:success, response.body}
      elsif response.headers["WWW-Authenticate"]? =~ /error_description="(.+?)"/
        {:error, $1}
      else
        Log.trace { response.inspect }
        {:error, response.body? || ""}
      end
    end

    private def self.post(path, body)
      HTTP::Client.post(
        "#{Settings.origin}#{path}",
        headers: HTTP::Headers{"Authorization" => "Bearer #{Settings.access_token}"},
        body: body
      )
    end
  end
end
