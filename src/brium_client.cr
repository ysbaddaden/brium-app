require "http"
require "./settings"

module BriumApp
  module BriumClient
    def self.messages(log : String) : {Symbol, String}
      response = post("/api/messages", body: log)
      if response.success?
        {:success, response.body}
      else
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
