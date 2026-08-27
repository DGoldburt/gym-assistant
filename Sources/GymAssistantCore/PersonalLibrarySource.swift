import CryptoKit
import Foundation

public struct PersonalLibrarySourceEvidence: Equatable, Sendable {
    public let note: String
    public let line: String
    public let occurrenceCount: Int
}

public struct PersonalLibraryObservation: Equatable, Sendable {
    public let id: ExerciseObservationID
    public let observedName: String
    public let normalizedName: String
    public let occurrenceCount: Int
    public let sources: [PersonalLibrarySourceEvidence]
}

public struct PersonalLibrarySource: Equatable, Sendable {
    public let sourceHash: String
    public let recordCount: Int
    public let occurrenceCount: Int
    public let observations: [PersonalLibraryObservation]

    public func ingestion(
        sourceReference: String = "personal-library-import"
    ) -> (ExerciseObservationIngestion, [IngestedExerciseObservation]) {
        let ingestionID = "personal-library:\(sourceHash)"
        let ingestion = ExerciseObservationIngestion(
            id: ingestionID,
            sourceKind: "personal-library",
            sourceReference: sourceReference,
            sourceFingerprint: sourceHash
        )
        let items = observations.map { item in
            var occurrenceCounts: [String: (reference: String, evidence: String, count: Int)] = [:]
            for source in item.sources {
                let key = "\(source.note)\u{0}\(source.line)"
                var value = occurrenceCounts[key] ?? (source.note, source.line, 0)
                value.count += source.occurrenceCount
                occurrenceCounts[key] = value
            }
            return IngestedExerciseObservation(
                observation: .init(
                    id: item.id,
                    observedName: item.observedName,
                    source: .init(adapter: ingestion.sourceKind, reference: ingestionID),
                    occurrenceCount: item.occurrenceCount
                ),
                occurrences: occurrenceCounts.values.sorted {
                    if $0.reference != $1.reference { return $0.reference < $1.reference }
                    return $0.evidence < $1.evidence
                }.map {
                    .init(
                        sourceReference: $0.reference,
                        evidence: $0.evidence,
                        occurrenceCount: $0.count
                    )
                }
            )
        }
        return (ingestion, items)
    }
}

public enum PersonalLibrarySourceError: Error, Equatable {
    case invalidUTF8
    case malformedCSV(record: Int)
    case invalidHeader
    case invalidRecord(record: Int)
    case unsupportedStatus(record: Int, status: String)
}

public struct PersonalLibraryCSVAdapter: Sendable {
    private static let expectedHeader = [
        "observed_name_verbatim",
        "source_note",
        "source_line_verbatim",
        "occurrence_count",
        "extraction_status",
        "extraction_note",
    ]

    private let normalizer: BasicExerciseNameNormalizer

    public init(normalizer: BasicExerciseNameNormalizer = .init()) {
        self.normalizer = normalizer
    }

    public func parse(data: Data) throws -> PersonalLibrarySource {
        guard let text = String(data: data, encoding: .utf8) else {
            throw PersonalLibrarySourceError.invalidUTF8
        }
        let normalizedLineEndings = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        var records = try CSVRecordParser().parse(normalizedLineEndings)
        if !records.isEmpty, !records[0].isEmpty {
            records[0][0] = records[0][0].replacingOccurrences(of: "\u{feff}", with: "")
        }
        guard records.first == Self.expectedHeader else {
            throw PersonalLibrarySourceError.invalidHeader
        }

        var grouped: [String: (display: String, count: Int, sources: [PersonalLibrarySourceEvidence])] = [:]
        for (offset, fields) in records.dropFirst().enumerated() {
            let recordNumber = offset + 2
            guard fields.count == Self.expectedHeader.count,
                  let count = Int(fields[3]), count > 0,
                  !fields[0].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  !fields[1].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  !fields[2].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw PersonalLibrarySourceError.invalidRecord(record: recordNumber)
            }
            guard fields[4] == "plausible_exercise" else {
                throw PersonalLibrarySourceError.unsupportedStatus(record: recordNumber, status: fields[4])
            }
            let display = fields[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let normalized = try normalizer.normalize(display)
            var group = grouped[normalized] ?? (display, 0, [])
            group.count += count
            group.sources.append(.init(note: fields[1], line: fields[2], occurrenceCount: count))
            grouped[normalized] = group
        }

        let sourceHash = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        let observations = grouped.map { normalized, group in
            let digest = SHA256.hash(data: Data("\(sourceHash)\u{0}\(normalized)".utf8))
                .map { String(format: "%02x", $0) }.joined()
            return PersonalLibraryObservation(
                id: .init(rawValue: digest),
                observedName: group.display,
                normalizedName: normalized,
                occurrenceCount: group.count,
                sources: group.sources
            )
        }.sorted { lhs, rhs in
            if lhs.normalizedName != rhs.normalizedName { return lhs.normalizedName < rhs.normalizedName }
            return lhs.id.rawValue < rhs.id.rawValue
        }

        return .init(
            sourceHash: sourceHash,
            recordCount: records.count - 1,
            occurrenceCount: observations.reduce(0) { $0 + $1.occurrenceCount },
            observations: observations
        )
    }
}

private struct CSVRecordParser {
    func parse(_ text: String) throws -> [[String]] {
        var records: [[String]] = []
        var record: [String] = []
        var field = ""
        var quoted = false
        var index = text.startIndex

        func finishField() {
            record.append(field)
            field = ""
        }

        func finishRecord() {
            finishField()
            records.append(record)
            record = []
        }

        while index < text.endIndex {
            let character = text[index]
            let next = text.index(after: index)
            if quoted {
                if character == "\"" {
                    if next < text.endIndex, text[next] == "\"" {
                        field.append("\"")
                        index = text.index(after: next)
                        continue
                    }
                    quoted = false
                } else {
                    field.append(character)
                }
            } else {
                switch character {
                case "\"":
                    if field.isEmpty {
                        quoted = true
                    } else {
                        field.append(character)
                    }
                case ",": finishField()
                case "\n": finishRecord()
                case "\r":
                    if next < text.endIndex, text[next] == "\n" {
                        index = next
                    }
                    finishRecord()
                default: field.append(character)
                }
            }
            index = text.index(after: index)
        }

        guard !quoted else {
            throw PersonalLibrarySourceError.malformedCSV(record: records.count + 1)
        }
        if !field.isEmpty || !record.isEmpty { finishRecord() }
        return records
    }
}
