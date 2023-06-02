.POSIX:

CRYSTAL = crystal
CRFLAGS =

all: bin/brium

run: bin/brium
	bin/brium

bin/brium: src/*.cr lib/*/src/*.cr lib/*/src/**/*.cr
	$(CRYSTAL) build $(CRFLAGS) -Dpreview_mt src/main.cr -o bin/brium
