.DEFAULT_GOAL := default

SWIFTC := xcrun swiftc
TARGET := build/lsau
SOURCES := main.swift

default: $(TARGET)

$(TARGET): $(SOURCES)
	mkdir -p build
	$(SWIFTC) -O -framework AudioToolbox -o $(TARGET) $(SOURCES)

clean:
	rm -rf build
