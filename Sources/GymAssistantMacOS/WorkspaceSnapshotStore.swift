import AppKit
import GymAssistantWorkspace

@MainActor public enum RichTextArchive {
    public static func encode(_ text: NSAttributedString) throws -> Data {
        try NSKeyedArchiver.archivedData(withRootObject: text, requiringSecureCoding: true)
    }
    public static func decode(_ data: Data) throws -> NSAttributedString {
        guard let result = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSAttributedString.self, from: data)
        else { throw WorkspaceError.invalidArchive }
        return result
    }
}

public enum SnapshotSavePhase: Sendable { case staged, validated, backedUp, promoted, reopened }
public enum SnapshotStoreError: Error, Equatable { case unavailable, identityMismatch, staleRevision, unsafeExistingFile }
public struct LoadedWorkspace {
    public let snapshot: WorkspaceSnapshot
    public let recoveredFromPrevious: Bool
}
public struct StoredWorkspaceAnchor: Decodable {
    public let schemaVersion: Int
    public let workspaceID: WorkspaceID
    public let anchor: SessionAnchor
    public let boundaryProtection: BoundaryEditProtection?
}

/// Store only local workspace snapshots. It has no Notes or provider dependency.
/// Serialized by the owning main-actor workspace; no cross-process writer is supported.
@MainActor public final class WorkspaceSnapshotStore {
    public let directory: URL
    private let fileManager: FileManager
    private let fault: ((SnapshotSavePhase) throws -> Void)?
    public init(directory: URL, fileManager: FileManager = .default,
                fault: ((SnapshotSavePhase) throws -> Void)? = nil) {
        self.directory = directory; self.fileManager = fileManager; self.fault = fault
    }
    public func currentURL(for id: WorkspaceID) -> URL {
        directory.appendingPathComponent(id.rawValue.uuidString + ".json")
    }
    public func previousURL(for id: WorkspaceID) -> URL {
        directory.appendingPathComponent(id.rawValue.uuidString + ".previous.json")
    }
    /// Discover all saved owners without unarchiving inactive rich-text editors.
    /// Damaged/unknown records fail visibly; they must not become vacant regions.
    public func storedAnchors() throws -> [StoredWorkspaceAnchor] {
        guard fileManager.fileExists(atPath: directory.path) else { return [] }
        let files = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        var ids: Set<UUID> = []
        for file in files where file.pathExtension == "json" {
            let stem = file.deletingPathExtension().lastPathComponent.replacingOccurrences(of: ".previous", with: "")
            if let id = UUID(uuidString: stem) { ids.insert(id) }
        }
        return try ids.sorted { $0.uuidString < $1.uuidString }.map { raw in
            let id = WorkspaceID(raw)
            let current = currentURL(for: id)
            let source = fileManager.fileExists(atPath: current.path) ? current : previousURL(for: id)
            let value = try JSONDecoder().decode(StoredWorkspaceAnchor.self, from: Data(contentsOf: source))
            guard WorkspaceSnapshot.supportsSchema(value.schemaVersion) else { throw WorkspaceError.unsupportedSchema(value.schemaVersion) }
            guard !value.anchor.isUnrecorded || (value.schemaVersion >= 2 && value.anchor.baselineText.isEmpty
                && value.anchor.sourceEvidence == nil && value.boundaryProtection == nil)
            else { throw WorkspaceError.invalidSnapshot }
            guard value.workspaceID == id, !value.anchor.noteID.rawValue.isEmpty else { throw SnapshotStoreError.identityMismatch }
            return value
        }
    }
    private func validated(_ data: Data, id: WorkspaceID) throws -> WorkspaceSnapshot {
        let value = try JSONDecoder().decode(WorkspaceSnapshot.self, from: data)
        try value.validate()
        guard value.workspaceID == id else { throw SnapshotStoreError.identityMismatch }
        let rich = try RichTextArchive.decode(value.richTextArchive)
        guard rich.string == value.text else { throw WorkspaceError.invalidArchive }
        return value
    }
    public func load(id: WorkspaceID) throws -> LoadedWorkspace? {
        let current = currentURL(for: id), previous = previousURL(for: id)
        if fileManager.fileExists(atPath: current.path) {
            do { return LoadedWorkspace(snapshot: try validated(Data(contentsOf: current), id: id), recoveredFromPrevious: false) }
            catch WorkspaceError.unsupportedSchema(let version) { throw WorkspaceError.unsupportedSchema(version) }
            catch {
                guard fileManager.fileExists(atPath: previous.path) else { throw SnapshotStoreError.unavailable }
                return LoadedWorkspace(snapshot: try validated(Data(contentsOf: previous), id: id), recoveredFromPrevious: true)
            }
        }
        if fileManager.fileExists(atPath: previous.path) {
            return LoadedWorkspace(snapshot: try validated(Data(contentsOf: previous), id: id), recoveredFromPrevious: true)
        }
        return nil
    }
    public func save(_ snapshot: WorkspaceSnapshot) throws {
        let data = try JSONEncoder().encode(snapshot)
        _ = try validated(data, id: snapshot.workspaceID)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true,
                                        attributes: [.posixPermissions: 0o700])
        let current = currentURL(for: snapshot.workspaceID)
        let previous = previousURL(for: snapshot.workspaceID)
        let stage = directory.appendingPathComponent(".candidate-" + UUID().uuidString)
        defer { try? fileManager.removeItem(at: stage) }
        // Do not overwrite either unreadable slot. Recovery is explicit, not a new empty session.
        if fileManager.fileExists(atPath: previous.path) {
            do { _ = try validated(Data(contentsOf: previous), id: snapshot.workspaceID) }
            catch { throw SnapshotStoreError.unsafeExistingFile }
        }
        var existing: Data?
        if fileManager.fileExists(atPath: current.path) {
            let raw = try Data(contentsOf: current)
            let old = try validated(raw, id: snapshot.workspaceID)
            guard old.anchor.noteID == snapshot.anchor.noteID, old.anchor.sessionID == snapshot.anchor.sessionID
            else { throw SnapshotStoreError.identityMismatch }
            guard snapshot.schemaVersion >= old.schemaVersion,
                  old.anchor.isUnrecorded || !snapshot.anchor.isUnrecorded else { throw SnapshotStoreError.identityMismatch }
            guard snapshot.revision >= old.revision else { throw SnapshotStoreError.staleRevision }
            existing = raw
        }
        try data.write(to: stage, options: .atomic)
        try fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: stage.path)
        try fault?(.staged)
        _ = try validated(Data(contentsOf: stage), id: snapshot.workspaceID)
        try fault?(.validated)
        if let existing {
            try existing.write(to: previous, options: .atomic)
            try fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: previous.path)
        }
        try fault?(.backedUp)
        try data.write(to: current, options: .atomic)
        try fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: current.path)
        try fault?(.promoted)
        guard try validated(Data(contentsOf: current), id: snapshot.workspaceID) == snapshot else {
            throw WorkspaceError.invalidSnapshot
        }
        try fault?(.reopened)
        // Only returning successfully acknowledges this revision.
    }
}
