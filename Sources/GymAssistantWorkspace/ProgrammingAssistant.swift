import Foundation

public enum ProfileEvidenceKind: String, Codable, Sendable {
    case authored, confirmedTendency, inferred, constraint, scientificClaim
}
public struct ProfileEntry: Codable, Equatable, Sendable {
    public let wording: String
    public let source: String
    public let kind: ProfileEvidenceKind
    public let confirmed: Bool
    public let scope: String?
    public let exceptions: [String]
    public init(wording: String, source: String, kind: ProfileEvidenceKind, confirmed: Bool,
                scope: String? = nil, exceptions: [String] = []) {
        self.wording = wording; self.source = source; self.kind = kind; self.confirmed = confirmed
        self.scope = scope; self.exceptions = exceptions
    }
}
public struct CoachingProfile: Codable, Equatable, Sendable {
    public let version: String
    public let entries: [ProfileEntry]
    public init(version: String, entries: [ProfileEntry]) { self.version = version; self.entries = entries }
}

/// Application-owned immutable inputs, not an API payload or a tool-capable agent.
public struct ProgrammingRequest: Equatable, Sendable {
    public let id: UUID
    public let workspaceID: WorkspaceID
    public let sessionID: SessionID
    public let conversationID: ConversationID
    public let noteID: NoteID
    public let observationID: UUID
    public let revision: Int
    public let question: String
    public let noteContext: String
    public let scratchpad: String
    public let sessionRecordingState: SessionRecordingState
    public let conversation: [ConversationMessage]
    public let profile: CoachingProfile
}
public struct ProgrammingResponse: Equatable, Sendable {
    public let requestID: UUID
    public let text: String
    public init(requestID: UUID, text: String) { self.requestID = requestID; self.text = text }
}
public enum AssistantFailure: Error, Equatable, Sendable {
    case cancelled, transport, provider, sizeLimit
}
public protocol ProgrammingAssistant: Sendable {
    func reply(to request: ProgrammingRequest) async throws -> ProgrammingResponse
}

public enum ProgramContextAssembler {
    public static func assemble(note: NoteSnapshot, association: SessionAssociation,
                                workspace: WorkspaceSnapshot, profile: CoachingProfile,
                                question: String, maximumContextBytes: Int) throws -> ProgrammingRequest {
        try workspace.validate()
        guard !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw WorkspaceError.emptyQuestion }
        guard !workspace.anchor.isUnrecorded, note.id == workspace.anchor.noteID, association.noteID == note.id,
              association.sessionID == workspace.anchor.sessionID, association.observationID == note.observationID
        else { throw WorkspaceError.staleAssociation }
        guard association.range.isParagraphAligned(in: note.text) else { throw WorkspaceError.invalidRange }
        let context = (note.text as NSString).replacingCharacters(in: association.range.nsRange, with: workspace.text)
        return try request(note: note, workspace: workspace, profile: profile, question: question,
                           context: context, maximumContextBytes: maximumContextBytes)
    }

    public static func assembleUnrecorded(note: NoteSnapshot, workspace: WorkspaceSnapshot,
                                         profile: CoachingProfile, question: String,
                                         maximumContextBytes: Int) throws -> ProgrammingRequest {
        try workspace.validate()
        guard !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw WorkspaceError.emptyQuestion }
        guard workspace.anchor.isUnrecorded, workspace.anchor.noteID == note.id else { throw WorkspaceError.staleAssociation }
        let context = note.text + "\n\n[Unrecorded scratchpad session — addition, not yet in Notes]\n" + workspace.text
        return try request(note: note, workspace: workspace, profile: profile, question: question,
                           context: context, maximumContextBytes: maximumContextBytes)
    }

    private static func request(note: NoteSnapshot, workspace: WorkspaceSnapshot, profile: CoachingProfile,
                                question: String, context: String, maximumContextBytes: Int) throws -> ProgrammingRequest {
        let conversation = workspace.messages.filter { $0.conversationID == workspace.conversationID }
        let profileBytes = try JSONEncoder().encode(profile.entries).count
        // Local byte budget is explicit; model-specific token limits belong to the adapter.
        let bytes = context.utf8.count + workspace.text.utf8.count + question.utf8.count + profileBytes
            + conversation.reduce(0) { $0 + $1.text.utf8.count }
        guard maximumContextBytes > 0, bytes <= maximumContextBytes else { throw WorkspaceError.oversizedContext }
        return ProgrammingRequest(id: UUID(), workspaceID: workspace.workspaceID, sessionID: workspace.anchor.sessionID,
            conversationID: workspace.conversationID, noteID: note.id, observationID: note.observationID,
            revision: workspace.revision, question: question, noteContext: context, scratchpad: workspace.text,
            sessionRecordingState: workspace.anchor.isUnrecorded ? .unrecorded : .recorded,
            conversation: conversation, profile: profile)
    }
}

/// One active request per workspace. Typed follow-ups remain in the UI composer.
public struct RequestGate: Sendable {
    public private(set) var active: ProgrammingRequest?
    public init() {}
    public mutating func begin(_ request: ProgrammingRequest) throws {
        guard active == nil else { throw WorkspaceError.requestAlreadyRunning }
        active = request
    }
    public mutating func stop() { active = nil }
    public mutating func finish(_ response: ProgrammingResponse) -> ProgrammingRequest? {
        guard let request = active, request.id == response.requestID else { return nil }
        active = nil
        return request
    }
}

public struct FakeProgrammingAssistant: ProgrammingAssistant {
    public let delay: Duration
    public init(delay: Duration = .seconds(1)) { self.delay = delay }
    public func reply(to request: ProgrammingRequest) async throws -> ProgrammingResponse {
        try await Task.sleep(for: delay)
        try Task.checkCancellation()
        let mode = request.sessionRecordingState == .unrecorded ? "the unrecorded session added separately" : "the associated session replaced by your scratchpad"
        return ProgrammingResponse(requestID: request.id,
            text: "Offline test reply — not exercise advice.\nI received scratchpad revision \(request.revision) and the supplied Notes context with \(mode).\nQuestion: \(request.question)\n\nKeep refining the scratchpad; the next question will use its latest text.")
    }
}
