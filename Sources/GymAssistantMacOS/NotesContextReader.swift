import AppKit
import ApplicationServices
import GymAssistantWorkspace

/// Read-only Automation boundary. All Apple events run on one worker queue, never
/// the editor thread. Reads never request consent; onboarding calls requestAccess.
public final class NotesContextReader: NotesContextReading, Sendable {
    private static let queue = DispatchQueue(label: "org.gymassistant.notes-reader")

    public init() {}

    public func requestAccess() async throws {
        try await perform { try Self.checkPermission(prompt: true) }
    }

    public func captureSelectedNote() async throws -> NoteSnapshot {
        try await perform {
            try Self.checkPermission(prompt: false)
            return try Self.snapshot(Self.execute(target: """
                set chosen to selection
                if (count of chosen) is not 1 then error number -1700
                set n to item 1 of chosen
                """, metadataOnly: false))
        }
    }

    public func read(id: NoteID) async throws -> NoteSnapshot {
        try await perform {
            try Self.checkPermission(prompt: false)
            let value = try Self.snapshot(Self.execute(target: Self.target(id), metadataOnly: false))
            guard value.id == id else { throw NotesReadError.unavailable }
            return value
        }
    }

    public func metadata(id: NoteID) async throws -> NoteMetadata {
        try await perform {
            try Self.checkPermission(prompt: false)
            let value = try Self.execute(target: Self.target(id), metadataOnly: true)
            guard value.numberOfItems == 2,
                  let returnedID = value.atIndex(1)?.stringValue, returnedID == id.rawValue,
                  let date = value.atIndex(2)?.dateValue else { throw NotesReadError.unavailable }
            return NoteMetadata(id: id, modifiedAt: date)
        }
    }

    private func perform<T: Sendable>(_ operation: @escaping @Sendable () throws -> T) async throws -> T {
        try Task.checkCancellation()
        let value: T = try await withCheckedThrowingContinuation { continuation in
            Self.queue.async { continuation.resume(with: Result { try operation() }) }
        }
        try Task.checkCancellation()
        return value
    }

    private static func checkPermission(prompt: Bool) throws {
        let descriptor = NSAppleEventDescriptor(bundleIdentifier: "com.apple.Notes")
        guard var target = descriptor.aeDesc?.pointee else { throw NotesReadError.unavailable }
        let result = AEDeterminePermissionToAutomateTarget(&target, AEEventClass(kAECoreSuite),
                                                          AEEventID(kAEGetData), prompt)
        guard result == noErr else {
            if result == -1743 || result == -1744 { throw NotesReadError.permission }
            throw NotesReadError.unavailable
        }
    }

    // Only an opaque note identity enters the script, as a quoted literal. Never
    // evaluate a title, note body, or user prompt as AppleScript source.
    static func target(_ id: NoteID) -> String {
        "set n to note id " + literal(id.rawValue)
    }

    static func literal(_ value: String) -> String {
        "\"" + value.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\n", with: "\\n") + "\""
    }

    static func script(target: String, metadataOnly: Bool) -> String {
        // Metadata must not request body/plaintext, even on a very large note.
        let fields = metadataOnly ? "{id of n, modification date of n}"
            : "{id of n, body of n, plaintext of n, modification date of n}"
        return """
        with timeout of 2 seconds
            tell application id "com.apple.Notes"
                \(target)
                return \(fields)
            end tell
        end timeout
        """
    }

    private static func execute(target: String, metadataOnly: Bool) throws -> NSAppleEventDescriptor {
        var error: NSDictionary?
        guard let script = NSAppleScript(source: script(target: target, metadataOnly: metadataOnly)) else {
            throw NotesReadError.unavailable
        }
        let result = script.executeAndReturnError(&error)
        if let error {
            switch (error[NSAppleScript.errorNumber] as? NSNumber)?.intValue {
            case -1743, -1744: throw NotesReadError.permission
            case -1728: throw NotesReadError.notFound
            case -1700: throw NotesReadError.ambiguousSelection
            default: throw NotesReadError.unavailable
            }
        }
        return result
    }

    private static func snapshot(_ result: NSAppleEventDescriptor) throws -> NoteSnapshot {
        guard result.numberOfItems == 4,
              let id = result.atIndex(1)?.stringValue, !id.isEmpty,
              let html = result.atIndex(2)?.stringValue,
              let text = result.atIndex(3)?.stringValue,
              let date = result.atIndex(4)?.dateValue else { throw NotesReadError.unavailable }
        return NoteSnapshot(id: NoteID(id), text: text, html: html, modifiedAt: date)
    }
}
