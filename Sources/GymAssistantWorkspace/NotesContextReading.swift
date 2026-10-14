import Foundation

public enum NotesReadError: Error, Equatable, Sendable { case permission, ambiguousSelection, notFound, unavailable }
public struct NoteMetadata: Equatable, Sendable {
    public let id: NoteID
    public let modifiedAt: Date
    public init(id: NoteID, modifiedAt: Date) { self.id = id; self.modifiedAt = modifiedAt }
}
public protocol NotesContextReading: Sendable {
    func captureSelectedNote() async throws -> NoteSnapshot
    func read(id: NoteID) async throws -> NoteSnapshot
    func metadata(id: NoteID) async throws -> NoteMetadata
}
