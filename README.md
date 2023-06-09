# Brium Desktop App

A simple client to https://brium.me written Crystal using the Gtk3 library.

Only tested on Linux Elementary OS 6.1, but should be compatible with any Linux
or macOS with Gtk3 installed. It might also run on Windows.

![screenshot](https://user-images.githubusercontent.com/47380/235488176-6fe23c84-cb9b-4a69-81c9-75ae2a98b3ee.png)

## Caveats

### Event Loop

The program must enable MT in order to run the Gtk main loop in the main thread,
and every other fibers in parallel in at least one other thread.

We might want to look into integrating the Gtk event loop with the Crystal event
loop as per <https://docs.gtk.org/glib/method.MainContext.set_poll_func.html>.
Or maybe we could start the Gtk main loop in its own dedicated thread (not
associated to MT).

### GC

We must keep references to every GObject we create and are still present on the
UI, otherwise the GC will collect them, and the GTK application will start
logging critical errors and warnings, and creashing or exiting unexpectedly.

Maybe the GTK4 bindings don't have that issue?

Using `Gtk::Builder` could help: instead of manually creating GObjects the
builder would do the job, hence create them in Gtk land, not in Crystal.

## Contributors

- Julien Portalier
