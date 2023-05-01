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
        <span color="#1F85C7"><b>Me:</b> #{sanitized_message}</span>
        <span size="small" foreground="#808080">Sent on #{@timestamp}</span>
        XML
      in .received?
        <<-XML
        <b>Brium:</b> #{sanitized_message}
        <span size="small" foreground="#808080">Received on #{@timestamp}</span>
        XML
      in .failed?
        <<-XML
        <span color="red"><b>Failed:</b> #{sanitized_message}</span>
        <span size="small" foreground="#808080">Received on #{@timestamp}</span>
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
