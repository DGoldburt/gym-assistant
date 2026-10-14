import Foundation

public struct ProgramParagraph: Codable, Equatable, Sendable {
    public struct Mark: Codable, Equatable, Sendable {
        public enum Kind: String, Codable, Sendable { case bold, italic, underline, link }
        public let range: SourceRange
        public let kind: Kind
        public let value: String?
        public init(range: SourceRange, kind: Kind, value: String? = nil) {
            self.range = range; self.kind = kind; self.value = value
        }
    }
    public let text: String
    public let headingLevel: Int
    public let listStyle: String?
    public let marks: [Mark]
    public init(text: String, headingLevel: Int = 0, listStyle: String? = nil, marks: [Mark] = []) {
        self.text = text; self.headingLevel = headingLevel; self.listStyle = listStyle; self.marks = marks
    }
    public var label: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }
}

public struct SessionSourceEvidence: Codable, Equatable, Sendable {
    public let paragraphs: [ProgramParagraph]
    public init(paragraphs: [ProgramParagraph]) { self.paragraphs = paragraphs }
    public var text: String { paragraphs.map(\.text).joined() }
    /// Only the outer label is excluded; nested week headings and formatting stay.
    public var body: [ProgramParagraph] { Array(paragraphs.dropFirst()) }
}

public struct SessionCandidate: Equatable, Sendable {
    public let range: SourceRange
    public let evidence: SessionSourceEvidence
    public let needsClassification: Bool
    public var label: String { evidence.paragraphs.first?.label ?? "" }
}

public struct ProgramDocument: Sendable {
    public let snapshot: NoteSnapshot
    public let paragraphs: [ProgramParagraph]
    public let ranges: [SourceRange]
    public init(snapshot: NoteSnapshot, paragraphs: [ProgramParagraph]) throws {
        guard paragraphs.map(\.text).joined() == snapshot.text else { throw WorkspaceError.invalidRange }
        var offset = 0
        var ranges: [SourceRange] = []
        for paragraph in paragraphs {
            let range = SourceRange(location: offset, length: (paragraph.text as NSString).length)
            guard range.isValid(in: snapshot.text),
                  (snapshot.text as NSString).paragraphRange(for: NSRange(location: offset, length: 0)) == range.nsRange,
                  (0...6).contains(paragraph.headingLevel) else {
                throw WorkspaceError.invalidRange
            }
            ranges.append(range); offset += range.length
        }
        self.snapshot = snapshot; self.paragraphs = paragraphs; self.ranges = ranges
    }

    public func evidence(in range: SourceRange) throws -> SessionSourceEvidence {
        guard range.isParagraphAligned(in: snapshot.text) else { throw WorkspaceError.invalidRange }
        let selected = paragraphs.indices.filter {
            ranges[$0].location >= range.location && NSMaxRange(ranges[$0].nsRange) <= NSMaxRange(range.nsRange)
        }
        guard let first = selected.first, let last = selected.last,
              ranges[first].location == range.location,
              NSMaxRange(ranges[last].nsRange) == NSMaxRange(range.nsRange) else { throw WorkspaceError.invalidRange }
        return SessionSourceEvidence(paragraphs: selected.map { paragraphs[$0] })
    }

    public func candidates() -> [SessionCandidate] {
        let peer = paragraphs.filter { Self.sessionLabel($0.label) != nil }
            .map(\.headingLevel).filter { $0 > 0 }.min()
        var starts: [(Int, Bool)] = []
        for (index, paragraph) in paragraphs.enumerated() {
            let label = paragraph.label.lowercased()
            if label == "parking lot" { continue }
            if index == 0 && paragraph.headingLevel == 1 && Self.sessionLabel(paragraph.label) == nil { continue }
            if label == "warmup" || label.range(of: #"^week\s+\d+$"#, options: .regularExpression) != nil { continue }
            if Self.sessionLabel(paragraph.label) != nil {
                if let peer, paragraph.headingLevel > peer { continue }
                starts.append((index, false))
            } else if paragraph.headingLevel > 0 && paragraph.headingLevel <= (peer ?? 2) {
                starts.append((index, true))
            }
        }
        return starts.enumerated().map { position, start in
            let end = position + 1 < starts.count ? starts[position + 1].0 : paragraphs.count
            let lower = ranges[start.0].location
            let upper = end < ranges.count ? ranges[end].location : (snapshot.text as NSString).length
            return SessionCandidate(range: SourceRange(location: lower, length: upper - lower),
                evidence: SessionSourceEvidence(paragraphs: Array(paragraphs[start.0..<end])), needsClassification: start.1)
        }
    }

    public static func sessionLabel(_ text: String) -> String? {
        let pattern = #"^Session\s+([0-9]+|[A-Za-z]+[0-9]*)(?:\s*[:–—-]\s*[^\r\n]*)?$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = regex.firstMatch(in: text, range: NSRange(location: 0, length: (text as NSString).length)) else { return nil }
        return (text as NSString).substring(with: match.range(at: 1)).uppercased()
    }
}

public enum SessionAssociationError: Error, Equatable { case stale, unknownSession, occupied, duplicateIdentity }

/// All saved anchors participate, including closed workspaces. Mapping never edits
/// scratchpads or advances confirmed content baselines.
public struct SessionAssociationRegistry: Sendable {
    public let noteID: NoteID
    public private(set) var observationID: UUID?
    public private(set) var mappings: [SessionID: SessionAssociation] = [:]
    public private(set) var unresolved: Set<SessionID> = []
    public private(set) var duplicateLabels: Set<String> = []
    private var anchors: [SessionID: SessionAnchor]
    private var previousParagraphs: [ProgramParagraph]?

    public init(noteID: NoteID, anchors: [SessionAnchor]) throws {
        guard anchors.allSatisfy({ $0.noteID == noteID }),
              Set(anchors.map(\.sessionID)).count == anchors.count else { throw SessionAssociationError.duplicateIdentity }
        self.noteID = noteID
        self.anchors = Dictionary(uniqueKeysWithValues: anchors.map { ($0.sessionID, $0) })
    }

    public func anchor(for id: SessionID) -> SessionAnchor? { anchors[id] }

    public mutating func observe(_ document: ProgramDocument) throws {
        guard document.snapshot.id == noteID else { throw SessionAssociationError.stale }
        if previousParagraphs == document.paragraphs {
            observationID = document.snapshot.observationID
            mappings = mappings.mapValues { old in
                SessionAssociation(sessionID: old.sessionID, noteID: old.noteID,
                    observationID: document.snapshot.observationID, range: old.range)
            }
            return
        }
        previousParagraphs = document.paragraphs
        let candidates = document.candidates()
        let labels = candidates.compactMap { ProgramDocument.sessionLabel($0.label) }
        duplicateLabels = Set(Dictionary(grouping: labels, by: { $0 }).filter { $0.value.count > 1 }.keys)
        observationID = document.snapshot.observationID
        mappings = [:]; unresolved = Set(anchors.keys)
        guard duplicateLabels.isEmpty else { return }
        for (id, anchor) in anchors {
            guard let evidence = anchor.sourceEvidence,
                  !evidence.body.map(\.text).joined().trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
            let owners = anchors.values.filter { $0.sourceEvidence?.body == evidence.body }
            let matches = candidates.filter {
                !$0.needsClassification && $0.evidence.body == evidence.body
                    && $0.evidence.paragraphs.first?.headingLevel == evidence.paragraphs.first?.headingLevel
            }
            guard owners.count == 1, matches.count == 1 else { continue }
            mappings[id] = SessionAssociation(sessionID: id, noteID: noteID,
                observationID: document.snapshot.observationID, range: matches[0].range)
            unresolved.remove(id)
        }
    }

    public mutating func confirm(sessionID: SessionID, range: SourceRange, in document: ProgramDocument) throws {
        guard observationID == document.snapshot.observationID, noteID == document.snapshot.id else { throw SessionAssociationError.stale }
        guard anchors[sessionID] != nil else { throw SessionAssociationError.unknownSession }
        let evidence = try document.evidence(in: range)
        guard !mappings.contains(where: { $0.key != sessionID && NSIntersectionRange($0.value.range.nsRange, range.nsRange).length > 0 }) else {
            throw SessionAssociationError.occupied
        }
        mappings[sessionID] = SessionAssociation(sessionID: sessionID, noteID: noteID,
            observationID: document.snapshot.observationID, range: range)
        // Association evidence is separate from the confirmed content baseline.
        anchors[sessionID]?.sourceEvidence = evidence
        unresolved.remove(sessionID)
    }
}
