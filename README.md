# lsau

`lsau` is a small macOS command-line tool that lists installed Audio Units and groups them by publisher.

## Install with Homebrew

```sh
brew tap grimdork/tools
brew install grimdork/tools/lsau
```

## Build

This project uses a simple `Makefile` rather than Swift Package Manager.

```sh
make
```

The default build is an optimized, stripped release binary written to:

```sh
./build/lsau
```

Build a separate debug binary with symbols:

```sh
make debug
```

That binary is written to:

```sh
./build/lsau-debug
```

## Usage

Show help:

```sh
./build/lsau -h
```

List all matching publishers and units:

```sh
./build/lsau
```

Filter by publisher:

```sh
./build/lsau -p apple
```

Filter by unit name:

```sh
./build/lsau -n delay
```

Combine filters:

```sh
./build/lsau -p apple -n delay
```

## Output

Results are grouped by publisher and sorted case-insensitively. If no Audio Units match the filters, `lsau` prints an error and exits non-zero.

## Clean

```sh
make clean
```

## License

MIT
