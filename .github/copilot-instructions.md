# Copilot instructions for `lsau`

## Build and run commands

Use the `Makefile`; this repository is **not** set up as a Swift Package Manager project.

- `make` builds the CLI to `build/lsau`
- `make clean` removes the build output
- `./build/lsau -h` prints usage
- `./build/lsau -p apple` filters publishers by case-insensitive substring
- `./build/lsau -n delay` filters unit names by case-insensitive substring

## High-level architecture

This is a small macOS command-line tool that enumerates installed Audio Units through the `AudioToolbox` framework and prints them grouped by publisher.

- `Makefile` is the entire build surface: it compiles `main.swift` with `xcrun swiftc -O -framework AudioToolbox` into `build/lsau`
- `main.swift` contains the full application:
  - `AudioUnitCatalog` walks `AudioComponentFindNext`, keeps only effect/music-effect/generator units, and returns `[publisher: [AudioUnitDescriptor]]`
  - `ArgumentParser` accepts only `-p`, `-n`, and help flags, producing an `Arguments` value
  - `LSAU.run()` coordinates parsing, rendering, usage handling, and process exit codes

## Key conventions

- Keep the project as a single-file CLI unless there is a clear need to split responsibilities; all current behavior is intentionally centralized in `main.swift`
- Preserve the current publisher naming behavior: prefer parsing `AudioComponentCopyName` as `Publisher: Unit`, then fall back to the four-character manufacturer code, and finally `"Unknown"` when the code is unavailable
- Filtering is accent-insensitive and case-insensitive through `String.foldedForMatch`; reuse that helper instead of adding ad hoc normalization
- Usage errors are modeled with `UsageError`: help (`-h` / `--help`) throws `UsageError(nil)` and exits successfully, while invalid arguments write the error plus usage text to stderr and exit non-zero
- Output is grouped by publisher, publishers and unit names are sorted with localized case-insensitive ordering, and a no-match result is treated as an error (`stderr` + non-zero exit)
