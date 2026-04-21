import Foundation
import AudioToolbox

struct AudioUnitDescriptor {
    let name: String
    let fullName: String
    let publisher: String
}

enum AudioUnitCatalog {
    static func systemUnits() -> [String: [AudioUnitDescriptor]] {
        var filter = AudioComponentDescription(
            componentType: 0,
            componentSubType: 0,
            componentManufacturer: 0,
            componentFlags: 0,
            componentFlagsMask: 0
        )

        var grouped: [String: [AudioUnitDescriptor]] = [:]
        var current = AudioComponentFindNext(nil, &filter)

        while let component = current {
            var description = AudioComponentDescription()
            _ = AudioComponentGetDescription(component, &description)

            if description.componentType == kAudioUnitType_Effect ||
                description.componentType == kAudioUnitType_MusicEffect ||
                description.componentType == kAudioUnitType_Generator {
                let fullName = componentName(component) ?? fourCharString(description.componentSubType)
                let naming = displayNaming(fullName: fullName, description: description)
                let descriptor = AudioUnitDescriptor(
                    name: naming.unitName,
                    fullName: fullName,
                    publisher: naming.publisher
                )
                grouped[naming.publisher, default: []].append(descriptor)
            }

            current = AudioComponentFindNext(component, &filter)
        }

        return grouped.mapValues { units in
            units.sorted { lhs, rhs in
                lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
        }
    }

    private static func componentName(_ component: AudioComponent) -> String? {
        var name: Unmanaged<CFString>?
        let status = AudioComponentCopyName(component, &name)
        guard status == noErr, let name else { return nil }
        return name.takeRetainedValue() as String
    }

    private static func publisherName(for description: AudioComponentDescription) -> String {
        let raw = fourCharString(description.componentManufacturer)
        return raw == "????" ? "Unknown" : raw
    }

    private static func displayNaming(fullName: String, description: AudioComponentDescription) -> (publisher: String, unitName: String) {
        let trimmed = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        if let separator = trimmed.firstIndex(of: ":") {
            let publisher = trimmed[..<separator].trimmingCharacters(in: .whitespacesAndNewlines)
            let unitName = trimmed[trimmed.index(after: separator)...].trimmingCharacters(in: .whitespacesAndNewlines)
            if !publisher.isEmpty, !unitName.isEmpty {
                return (publisher, unitName)
            }
        }

        let fallbackPublisher = publisherName(for: description)
        return (fallbackPublisher, trimmed)
    }

    private static func fourCharString(_ code: UInt32) -> String {
        let big = code.bigEndian
        let bytes: [UInt8] = [
            UInt8((big >> 24) & 0xFF),
            UInt8((big >> 16) & 0xFF),
            UInt8((big >> 8) & 0xFF),
            UInt8(big & 0xFF)
        ]
        return String(bytes: bytes, encoding: .macOSRoman) ?? String(format: "%08X", code)
    }
}

struct Arguments {
    var publisherFilter: String?
    var nameFilter: String?
}

enum ArgumentParser {
    static func parse(_ arguments: [String]) throws -> Arguments {
        var parsed = Arguments()
        var index = 0

        while index < arguments.count {
            let argument = arguments[index]
            switch argument {
            case "-p":
                index += 1
                guard index < arguments.count else {
                    throw UsageError("missing value for -p")
                }
                parsed.publisherFilter = arguments[index]
            case "-n":
                index += 1
                guard index < arguments.count else {
                    throw UsageError("missing value for -n")
                }
                parsed.nameFilter = arguments[index]
            case "-h", "--help":
                throw UsageError(nil)
            default:
                throw UsageError("unknown argument: \(argument)")
            }
            index += 1
        }

        return parsed
    }
}

struct UsageError: Error {
    let message: String?
    init(_ message: String?) {
        self.message = message
    }
}

enum LSAU {
    static func run() {
        do {
            let arguments = try ArgumentParser.parse(Array(CommandLine.arguments.dropFirst()))
            renderCatalog(arguments: arguments)
        } catch let error as UsageError {
            if let message = error.message {
                FileHandle.standardError.write(Data("Error: \(message)\n\n".utf8))
            }
            FileHandle.standardError.write(Data(usageText.utf8))
            exit(error.message == nil ? EXIT_SUCCESS : EXIT_FAILURE)
        } catch {
            FileHandle.standardError.write(Data("Error: \(error.localizedDescription)\n".utf8))
            exit(EXIT_FAILURE)
        }
    }

    private static func renderCatalog(arguments: Arguments) {
        let publisherFilter = arguments.publisherFilter?.foldedForMatch
        let nameFilter = arguments.nameFilter?.foldedForMatch
        let groups = AudioUnitCatalog.systemUnits()

        let publishers = groups.keys.sorted {
            $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
        }

        var printedAny = false

        for publisher in publishers {
            guard matches(publisher, filter: publisherFilter) else { continue }

            let units = groups[publisher, default: []].filter { unit in
                matches(unit.publisher, filter: publisherFilter) &&
                matches(unit.name, filter: nameFilter)
            }

            guard !units.isEmpty else { continue }

            printedAny = true
            print("\(publisher) (\(units.count))")
            for unit in units {
                print("  \(unit.name)")
            }
        }

        if !printedAny {
            FileHandle.standardError.write(Data("No Audio Units matched.\n".utf8))
            exit(EXIT_FAILURE)
        }
    }

    private static func matches(_ value: String, filter: String?) -> Bool {
        guard let filter, !filter.isEmpty else { return true }
        return value.foldedForMatch.contains(filter)
    }

    private static let usageText = """
    Usage: lsau [-p publisher-filter] [-n name-filter]

      -p    Filter publishers by case-insensitive substring
      -n    Filter plugin names by case-insensitive substring
      -h    Show this help

    """
}

private extension String {
    var foldedForMatch: String {
        folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }
}

LSAU.run()
