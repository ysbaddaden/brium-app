require "json"

module BriumApp
  class Settings
    DEFAULT_ORIGIN = "https://brium.me"

    # :nodoc:
    INSTANCE = new

    def self.configured? : Bool
      INSTANCE.configured?
    end

    def self.origin : String
      INSTANCE.origin
    end

    def self.access_token : String
      INSTANCE.access_token
    end

    def self.origin=(origin : String?) : String?
      INSTANCE.origin = origin
    end

    def self.access_token=(access_token : String?) : String?
      INSTANCE.access_token = access_token
    end

    def self.write_settings : Nil
      INSTANCE.write_settings
    end

    @origin : String?
    @access_token : String?

    protected def initialize
      read_settings
    end

    def configured? : Bool
      !!access_token?
    end

    {% if flag?(:release) %}
      def origin : String
        ENV.fetch("BRIUM_ORIGIN") { @origin || DEFAULT_ORIGIN }
      end

      def access_token : String
        ENV.fetch("BRIUM_ACCESS_TOKEN") { @access_token.not_nil! }
      end

      def access_token? : String?
        ENV.fetch("BRIUM_ACCESS_TOKEN", @access_token)
      end
    {% else %}
      def origin : String
        @origin || DEFAULT_ORIGIN
      end

      def access_token : String
        @access_token.not_nil!
      end

      def access_token? : String?
        @access_token
      end
    {% end %}

    def origin=(@origin : String?) : String?
    end

    def access_token=(@access_token : String?) : String?
    end

    def read_settings : Nil
      path = config_path("settings.json")
      if File.exists?(path)
        json = JSON.parse(File.read(path))
        @origin = json["origin"]?.try(&.as_s)
        @access_token = json["access_token"]?.try(&.as_s)
      end
    end

    def write_settings : Nil
      path = config_path("settings.json")
      Dir.mkdir_p(path.dirname)
      File.open(path, "w", File::Permissions.new(0o600)) { |io| to_json(io) }
    end

    def config_path(filename : String) : Path
      {% if flag?(:windows) %}
        Path["~/AppData/Local/brium", filename].expand(home: true)
      {% else %}
        Path[ENV.fetch("XDG_CONFIG_HOME", "~/.config"), "brium", filename].expand(home: true)
      {% end %}
    end

    def to_json(io : IO) : Nil
      {
        "version" => 0,
        "origin" => @origin,
        "access_token" => @access_token,
      }.to_json(io)
    end
  end
end
