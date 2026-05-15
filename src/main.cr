require "gobject/gtk"
require "log"

require "./*"

Log.setup_from_env(default_level: :info)
ctx = Fiber::ExecutionContext::Isolated.new(name: "GTK") do
  BriumApp::Application.new.run
end
ctx.wait
