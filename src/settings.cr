require "json"

module BriumApp
  class Settings
    DEFAULT_ORIGIN = "https://brium.me"

    # :nodoc:
    INSTANCE = new

    def self.origin : String
      INSTANCE.origin
    end

    def self.access_token : String
      INSTANCE.access_token
    end

    @origin : String?
    @access_token : String?

    protected def initialize
      read_settings
    end

    def configured? : Bool
      !!access_token?
    end

    def origin : String
      @origin ||= ENV.fetch("BRIUM_ORIGIN", DEFAULT_ORIGIN)
    end

    def origin=(origin : String) : String
      @origin = origin.rstrip('/')
      write_settings
      origin
    end

    def access_token : String
      @access_token || ENV["BRIUM_ACCESS_TOKEN"]
    end

    def access_token? : String?
      @access_token || ENV["BRIUM_ACCESS_TOKEN"]?
    end

    def access_token=(access_token : String) : String
      @access_token = access_token
      write_settings
      access_token
    end

    private def read_settings
      path = config_path("settings.json")
      if File.exists?(path)
        json = JSON.parse(File.read(path, "r"))
        @origin = json["origin"]?.try(&.as_s)
        @access_token = json["access_token"]?.try(&.as_s)
      end
    end

    private def write_settings
      path = config_path("settings.json")
      Dir.mkdir_p(path.dirname)
      File.open(path, "w", File::Permissions.new(0o600)) { |io| to_json(io) }
    end

    private def config_path(filename : String) : Path
      {% if flag?(:windows) %}
        Path["~/AppData/Local/brium", filename].expand(home: true)
      {% else %}
        Path[ENV.fetch("XDG_CONFIG_HOME", "~/.config"), "brium", filename].expand(home: true)
      {% end %}
    end

    private def to_json(io : IO) : String
      {
        "version" => 0,
        "origin" => @origin,
        "access_token" => @access_token,
      }.to_json(io)
    end
  end
end
