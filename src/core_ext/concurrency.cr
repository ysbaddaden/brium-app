module BriumApp
  # :nodoc:
  MAIN_THREAD = Thread.current

  # :nodoc:
  ALL_THREADS = [] of Thread

  Thread.unsafe_each do |thread|
    ALL_THREADS << thread unless thread == MAIN_THREAD
  end
end

{% if !flag?(:preview_mt) %}
  {% raise "ERROR: you must compile the application with -Dpreview_mt" %}
{% end %}

# Override `spawn` to never spawn into the main thread because it's blocked by
# GTK's main loop. We must always spawn fibers into the other threads.
def spawn(*, name : String? = nil, same_thread = false, &block)
  fiber = Fiber.new(name, &block)
  if same_thread
    fiber.@current_thread.set Thread.current
  elsif !BriumApp::ALL_THREADS.empty?
    fiber.@current_thread.set BriumApp::ALL_THREADS.sample
  end
  Crystal::Scheduler.enqueue(fiber)
  fiber
end

# Must start this cleanup loop manually because crystal kernel always spawns it
# on the main thread, that will be blocked by GTK's main loop:
spawn(name: "Fiber Clean Loop") do
  loop do
    sleep 5
    Fiber.stack_pool.collect
  end
end
