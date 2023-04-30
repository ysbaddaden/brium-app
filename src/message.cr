module BriumApp
  struct Message
    enum Type
      Sent
      Received
      Failed
    end

    getter type : Type
    getter message : String
    getter timestamp : Time

    def initialize(@type : Type, @message : String, @timestamp : Time = Time.local)
    end

    def to_pango_s : String
      case @type
      in .sent?
        <<-XML
        <span color="#1f85C7"><b>Me:</b> #{sanitized_message}</span>
        <span size="small" foreground="#999999">Sent on #{@timestamp}</span>
        XML
      in .received?
        <<-XML
        <span color="#666666"><b>Brium:</b> #{sanitized_message}</span>
        <span size="small" foreground="#999999">Received on #{@timestamp}</span>
        XML
      in .failed?
        <<-XML
        <span color="#666666"><b>Failed:</b> #{sanitized_message}</span>
        <span size="small" foreground="#999999">Received on #{@timestamp}</span>
        XML
      end
    end

    def sanitized_message
      message
        .gsub('<', "&lt;")
        .gsub('>', "&gt;")
    end
  end
end
