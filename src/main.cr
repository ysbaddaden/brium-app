require "gobject/gtk"
require "log"
require "./*"

{% if !flag?(:preview_mt) %}
  # we need preview_mt to turn-on thread safety, we can set CRYSTAL_WORKERS=1 to
  # start only one worker/scheduler thread
  {% raise "ERROR: you must compile the application with -Dpreview_mt" %}
{% end %}

Log.setup_from_env(default_level: :info)
done = Channel(Int32).new(0)

Thread.new do
  BriumApp::Application.new.run
  done.send(1)
end

done.receive
