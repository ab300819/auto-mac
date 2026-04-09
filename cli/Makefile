PREFIX ?= $(HOME)/.local
BINDIR = $(PREFIX)/bin

.PHONY: build install uninstall clean test

build:
	swift build -c release

install: build
	install -d $(BINDIR)
	install .build/release/auto-mac $(BINDIR)/auto-mac

uninstall:
	rm -f $(BINDIR)/auto-mac

clean:
	swift package clean

test:
	swift test
