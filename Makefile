.DEFAULT_GOAL := default

SWIFTC := xcrun swiftc
STRIP := xcrun strip
RELEASE_TARGET := build/lsau
DEBUG_TARGET := build/lsau-debug
SOURCES := main.swift

default: release

release: $(RELEASE_TARGET)

debug: $(DEBUG_TARGET)

$(RELEASE_TARGET): $(SOURCES)
	mkdir -p build
	$(SWIFTC) -O -framework AudioToolbox -o $(RELEASE_TARGET) $(SOURCES)
	$(STRIP) -S -x $(RELEASE_TARGET)

$(DEBUG_TARGET): $(SOURCES)
	mkdir -p build
	$(SWIFTC) -Onone -g -framework AudioToolbox -o $(DEBUG_TARGET) $(SOURCES)

clean:
	rm -rf build
