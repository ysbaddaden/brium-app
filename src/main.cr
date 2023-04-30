require "log"
require "./core_ext/concurrency"
require "./application"

Log.setup_from_env(default_level: :info)
BriumApp::Application.new.run
