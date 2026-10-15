import Foundation

public enum WorkspaceTag: Sendable {}
public enum SessionTag: Sendable {}
public enum ConversationTag: Sendable {}
public struct LocalID<Tag: Sendable>: Codable, Hashable, Sendable {
    public let rawValue: UUID
    public init(_ rawValue: UUID = UUID()) { self.rawValue = rawValue }
}
public typealias WorkspaceID = LocalID<WorkspaceTag>
public typealias SessionID = LocalID<SessionTag>
public typealias ConversationID = LocalID<ConversationTag>
public struct NoteID: Codable, Hashable, Sendable {
    public let rawValue: String
    public init(_ rawValue: String) { self.rawValue = rawValue }
}

/// UTF-16 offsets within one observed note, never a persistent session identity.
public struct SourceRange: Codable, Equatable, Sendable {
    public let location: Int
    public let length: Int
    public init(location: Int, length: Int) { self.location = location; self.length = length }
    public var nsRange: NSRange { NSRange(location: location, length: length) }
    public func isValid(in text: String) -> Bool {
        let count = (text as NSString).length
        return location >= 0 && length > 0 && location <= count && length <= count - location
    }
    public func isParagraphAligned(in text: String) -> Bool {
        guard isValid(in: text) else { return false }
        let source = text as NSString
        var boundaries: Set<Int> = [0, source.length]
        var offset = 0
        while offset < source.length {
            let paragraph = source.paragraphRange(for: NSRange(location: offset, length: 0))
            boundaries.insert(paragraph.location); boundaries.insert(NSMaxRange(paragraph))
            offset = NSMaxRange(paragraph)
        }
        return boundaries.contains(location) && boundaries.contains(location + length)
    }
}

public struct NoteSnapshot: Equatable, Sendable {
    public let id: NoteID
    public let observationID: UUID
    public let text: String
    public let html: String
    public let modifiedAt: Date
    public init(id: NoteID, observationID: UUID = UUID(), text: String, html: String = "", modifiedAt: Date = Date()) {
        self.id = id; self.observationID = observationID; self.text = text
        self.html = html; self.modifiedAt = modifiedAt
    }
}

public enum SessionRecordingState: String, Codable, Sendable { case recorded, unrecorded }

public struct SessionAnchor: Codable, Equatable, Sendable {
    public let sessionID: SessionID
    public let noteID: NoteID
    public var recordedHeading: String
    public var baselineText: String
    public var sourceEvidence: SessionSourceEvidence?
    /// Absent in schema-1 files, where every anchor described a recorded region.
    public var recordingState: SessionRecordingState?
    public var isUnrecorded: Bool { recordingState == .unrecorded }
    public init(sessionID: SessionID = SessionID(), noteID: NoteID, recordedHeading: String, baselineText: String,
                sourceEvidence: SessionSourceEvidence? = nil, recordingState: SessionRecordingState = .recorded) {
        self.sessionID = sessionID; self.noteID = noteID
        self.recordedHeading = recordedHeading; self.baselineText = baselineText
        self.sourceEvidence = sourceEvidence
        self.recordingState = recordingState
    }
}

/// Created only after association is checked against this observation.
public struct SessionAssociation: Equatable, Sendable {
    public let sessionID: SessionID
    public let noteID: NoteID
    public let observationID: UUID
    public let range: SourceRange
    public init(sessionID: SessionID, noteID: NoteID, observationID: UUID, range: SourceRange) {
        self.sessionID = sessionID; self.noteID = noteID; self.observationID = observationID; self.range = range
    }
}

public enum MessageRole: String, Codable, Sendable { case coach, assistant }
public enum MessageStatus: String, Codable, Sendable { case complete, pending, cancelled, interrupted, failed }
public struct ConversationMessage: Codable, Equatable, Sendable {
    public let id: UUID
    public let requestID: UUID
    public let conversationID: ConversationID
    public let role: MessageRole
    public var text: String
    public var status: MessageStatus
    public let scratchpadRevision: Int
    public let observationID: UUID
    public init(id: UUID = UUID(), requestID: UUID, conversationID: ConversationID, role: MessageRole,
                text: String, status: MessageStatus, scratchpadRevision: Int, observationID: UUID) {
        self.id = id; self.requestID = requestID; self.conversationID = conversationID
        self.role = role; self.text = text; self.status = status
        self.scratchpadRevision = scratchpadRevision; self.observationID = observationID
    }
}

public struct WorkspaceSnapshot: Codable, Equatable, Sendable {
    public static let currentSchema = 2
    public static func supportsSchema(_ version: Int) -> Bool { (1...currentSchema).contains(version) }
    public var schemaVersion: Int
    public let workspaceID: WorkspaceID
    public var anchor: SessionAnchor
    public var revision: Int
    public var text: String
    public var richTextArchive: Data
    public var messages: [ConversationMessage]
    public var conversationID: ConversationID
    public var composerText: String
    public var boundaryProtection: BoundaryEditProtection?
    public init(workspaceID: WorkspaceID = WorkspaceID(), anchor: SessionAnchor, revision: Int = 0,
                text: String, richTextArchive: Data, messages: [ConversationMessage] = [],
                conversationID: ConversationID = ConversationID(), composerText: String = "") {
        schemaVersion = Self.currentSchema; self.workspaceID = workspaceID; self.anchor = anchor
        self.revision = revision; self.text = text; self.richTextArchive = richTextArchive
        self.messages = messages; self.conversationID = conversationID
        self.composerText = composerText
    }
    public func validate() throws {
        guard Self.supportsSchema(schemaVersion) else { throw WorkspaceError.unsupportedSchema(schemaVersion) }
        guard revision >= 0, !anchor.noteID.rawValue.isEmpty, !richTextArchive.isEmpty,
              Set(messages.map(\.id)).count == messages.count,
              messages.allSatisfy({ $0.scratchpadRevision >= 0 && $0.scratchpadRevision <= revision })
        else { throw WorkspaceError.invalidSnapshot }
        if anchor.isUnrecorded {
            // No invented recorded range or baseline for a session not in Notes.
            guard schemaVersion >= 2, anchor.baselineText.isEmpty,
                  anchor.sourceEvidence == nil, boundaryProtection == nil else { throw WorkspaceError.invalidSnapshot }
        }
        if let boundaryProtection, !boundaryProtection.isValid(currentLength: (text as NSString).length) {
            throw WorkspaceError.invalidSnapshot
        }
    }
    public mutating func markInterruptedRequests() {
        for index in messages.indices where messages[index].status == .pending {
            messages[index].status = .interrupted
        }
    }
}

public enum WorkspaceError: Error, Equatable {
    case unsupportedSchema(Int), invalidSnapshot, invalidArchive, staleAssociation, invalidRange
    case emptyQuestion, oversizedContext, requestAlreadyRunning
}
