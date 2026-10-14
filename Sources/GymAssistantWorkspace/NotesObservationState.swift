import Foundation

/// Last observed source, never the scratchpad or its confirmed baseline. A stable
/// contentID lets consumers reuse parsed structure after an identical body read.
public struct NotesObservationState: Sendable {
    public let noteID: NoteID
    public private(set) var snapshot: NoteSnapshot?
    public private(set) var contentID: UUID?
    public private(set) var failure: NotesReadError?
    public private(set) var sequence: UInt64 = 0

    public init(noteID: NoteID) { self.noteID = noteID }

    public func requiresBody(after metadata: NoteMetadata) throws -> Bool {
        guard metadata.id == noteID else { throw NotesReadError.unavailable }
        return snapshot == nil || metadata.modifiedAt != snapshot?.modifiedAt
    }

    public mutating func accept(_ value: NoteSnapshot) throws {
        guard value.id == noteID else { throw NotesReadError.unavailable }
        if snapshot?.text != value.text || snapshot?.html != value.html { contentID = UUID() }
        snapshot = value
        failure = nil
        sequence += 1
    }

    public mutating func failed(_ error: NotesReadError) { failure = error; sequence += 1 }
}
