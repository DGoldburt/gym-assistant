import AppKit
import GymAssistantWorkspace

public enum SessionEntryError: Error, Equatable {
    case duplicateHeadings([String])
    case boundaryReviewRequired
    case unresolvedSavedWorkspace
    case recoveryRequired(WorkspaceID)
    case multipleUnrecordedWorkspaces
    case skeletonSourceChanged
}

/// Local entry preparation, invoked only after choosing the programming branch.
/// Selection is captured once; subsequent reads address that identity even if
/// the coach selects another note while the independent window is opening.
@MainActor public final class SessionWorkspaceEntry {
    private let store: WorkspaceSnapshotStore
    private let reader: any NotesContextReading
    private let pool: SessionNoteContextPool

    public init(store: WorkspaceSnapshotStore, reader: any NotesContextReading) {
        self.store = store; self.reader = reader
        pool = SessionNoteContextPool(store: store, reader: reader)
    }

    public func captureNote() async throws -> NoteID {
        let captured = try await reader.captureSelectedNote()
        try Task.checkCancellation()
        return captured.id
    }
    public func releaseSetAside(_ snapshot: WorkspaceSnapshot) { pool.releaseSetAside(snapshot) }

    /// An explicit record choice never substitutes current Notes for saved work.
    public struct ResumedSession {
        public let snapshot: WorkspaceSnapshot
        public let context: SessionNoteContext
        public let note: NoteSnapshot
    }
    public func resume(id: WorkspaceID) async throws -> ResumedSession {
        guard let loaded = try store.load(id: id), loaded.snapshot.isActive else {
            throw SessionEntryError.unresolvedSavedWorkspace
        }
        guard !loaded.recoveredFromPrevious else { throw SessionEntryError.recoveryRequired(id) }
        let context = try pool.context(for: loaded.snapshot.anchor.noteID)
        let document = try await context.refresh(for: .resume)
        try Task.checkCancellation()
        guard let current = try store.load(id: id), !current.recoveredFromPrevious, current.snapshot.isActive else {
            throw SessionEntryError.unresolvedSavedWorkspace
        }
        return ResumedSession(snapshot: current.snapshot, context: context, note: document.snapshot)
    }

    public struct PreparedSession {
        public let snapshot: WorkspaceSnapshot
        public let context: SessionNoteContext
        public let association: SessionAssociation
        public let note: NoteSnapshot
    }

    public struct UnrecordedSession: Sendable {
        public let snapshot: WorkspaceSnapshot
        public let context: SessionNoteContext
        public let note: NoteSnapshot
    }

    public struct NewSessionProposal {
        public let skeleton: SessionSkeleton
        public let source: ProgramDocument
        public let sourceRange: SourceRange
    }

    public struct BoundaryReview {
        public let document: ProgramDocument
        public let richText: NSAttributedString
        public let selected: SourceRange
        public let owners: [SessionBoundaryBrowser.Owner]
    }

    public func boundaryReview(in noteID: NoteID) async throws -> BoundaryReview {
        let context = try pool.context(for: noteID)
        let document = try await context.refresh(for: .resume)
        try Task.checkCancellation()
        guard let rich = context.richText, let selected = document.candidates().last?.range ?? document.ranges.first else {
            throw SessionEntryError.boundaryReviewRequired
        }
        return BoundaryReview(document: document, richText: rich, selected: selected,
            owners: context.registry.mappings.values.map {
                SessionBoundaryBrowser.Owner(label: context.registry.anchor(for: $0.sessionID)?.recordedHeading ?? "Saved session", range: $0.range)
            })
    }

    private func selectedRange(in document: ProgramDocument, review: BoundaryReview?, range: SourceRange?) throws -> SourceRange {
        if let review, let range {
            guard review.document.snapshot.id == document.snapshot.id,
                  review.document.paragraphs == document.paragraphs else { throw WorkspaceError.staleAssociation }
            _ = try document.evidence(in: range)
            return range
        }
        guard let candidate = document.candidates().last, !candidate.needsClassification else {
            throw SessionEntryError.boundaryReviewRequired
        }
        return candidate.range
    }

    public enum NewSessionPreparation {
        case resume(UnrecordedSession)
        case proposal(NewSessionProposal)
    }

    /// Preview only: no file creation, no question about the new label. Any
    /// unfamiliar headings remain visible as review items in the proposal.
    public func prepareNewSession(in noteID: NoteID, review: BoundaryReview? = nil, range: SourceRange? = nil) async throws -> NewSessionPreparation {
        let context = try pool.context(for: noteID)
        let document = try await context.refresh(for: .resume)
        try Task.checkCancellation()
        if let existing = try unrecorded(in: noteID, context: context, note: document.snapshot) {
            return .resume(existing)
        }
        guard context.registry.duplicateLabels.isEmpty else {
            throw SessionEntryError.duplicateHeadings(context.registry.duplicateLabels.sorted())
        }
        let sourceRange = try selectedRange(in: document, review: review, range: range)
        let previous = try document.evidence(in: sourceRange)
        let headings = document.candidates().map(\.label)
        return .proposal(NewSessionProposal(skeleton: try SessionSkeleton(previous: previous, existingHeadings: headings), source: document, sourceRange: sourceRange))
    }

    /// Explicit acceptance of session headings plus carried parking-lot ideas. A full read
    /// revalidates it, then lookup/save occur without suspension so simultaneous
    /// accepts in this app cannot create competing unrecorded scratchpads.
    public func acceptNewSession(_ proposal: NewSessionProposal) async throws -> UnrecordedSession {
        let noteID = proposal.source.snapshot.id
        let context = try pool.context(for: noteID)
        let document = try await context.refresh(for: .resume)
        try Task.checkCancellation()
        if let existing = try unrecorded(in: noteID, context: context, note: document.snapshot) { return existing }
        guard document.paragraphs == proposal.source.paragraphs else { throw SessionEntryError.skeletonSourceChanged }
        let rich = NSMutableAttributedString(string: "")
        let carriedCount = proposal.skeleton.carriedParkingLotParagraphCount
        for paragraph in proposal.skeleton.evidence.paragraphs.dropLast(carriedCount) {
            let style = NSMutableParagraphStyle(); style.headerLevel = paragraph.headingLevel
            rich.append(NSAttributedString(string: paragraph.text, attributes: [
                .paragraphStyle: style,
                .font: NSFont.boldSystemFont(ofSize: paragraph.headingLevel == 2 ? 22 : 18)
            ]))
        }
        if carriedCount > 0 {
            guard let sourceRich = context.richText else {
                throw WorkspaceError.staleAssociation
            }
            let length = proposal.skeleton.evidence.paragraphs.suffix(carriedCount)
                .reduce(0) { $0 + $1.text.utf16.count }
            let range = NSRange(location: NSMaxRange(proposal.sourceRange.nsRange) - length, length: length)
            guard range.location >= proposal.sourceRange.location,
                  NSMaxRange(range) <= sourceRich.length else { throw WorkspaceError.staleAssociation }
            rich.append(sourceRich.attributedSubstring(from: range))
        }
        var snapshot = WorkspaceSnapshot(anchor: SessionAnchor(noteID: noteID,
            recordedHeading: proposal.skeleton.evidence.paragraphs.first?.label ?? SessionSkeleton.placeholderHeading,
            baselineText: "", recordingState: .unrecorded), text: rich.string,
            richTextArchive: try RichTextArchive.encode(rich))
        snapshot.anchor.unrecordedOrigin = SessionSourceEvidence(paragraphs: document.paragraphs)
        try store.save(snapshot)
        return UnrecordedSession(snapshot: snapshot, context: context, note: document.snapshot)
    }

    private func unrecorded(in noteID: NoteID, context: SessionNoteContext, note: NoteSnapshot) throws -> UnrecordedSession? {
        let headers = try store.storedAnchors().filter { $0.isActive && $0.anchor.noteID == noteID && $0.anchor.isUnrecorded }
        guard headers.count <= 1 else { throw SessionEntryError.multipleUnrecordedWorkspaces }
        guard let header = headers.first else { return nil }
        guard let loaded = try store.load(id: header.workspaceID) else { throw SessionEntryError.unresolvedSavedWorkspace }
        guard !loaded.recoveredFromPrevious else { throw SessionEntryError.recoveryRequired(header.workspaceID) }
        return UnrecordedSession(snapshot: loaded.snapshot, context: context, note: note)
    }

    /// Last region in document order, never highest label or modification date.
    /// Does not silently classify an unknown heading or bypass a saved owner.
    public func latest(in noteID: NoteID, review: BoundaryReview? = nil, range: SourceRange? = nil) async throws -> PreparedSession {
        let context = try pool.context(for: noteID)
        let document = try await context.refresh(for: .resume)
        try Task.checkCancellation()
        guard context.registry.duplicateLabels.isEmpty else {
            throw SessionEntryError.duplicateHeadings(context.registry.duplicateLabels.sorted())
        }
        let selected = try selectedRange(in: document, review: review, range: range)
        let owners = context.registry.mappings.values.filter {
            NSIntersectionRange($0.range.nsRange, selected.nsRange).length > 0
        }
        let snapshot: WorkspaceSnapshot
        if let owner = owners.first {
            // A manually adjusted range needs its own explicit entry choice if
            // it overlaps multiple inferred regions; do not resize it on entry.
            guard owners.count == 1, owner.range == selected else {
                throw SessionEntryError.boundaryReviewRequired
            }
            let headers = try store.storedAnchors().filter {
                $0.isActive && $0.anchor.noteID == noteID && $0.anchor.sessionID == owner.sessionID
            }
            guard headers.count == 1, let header = headers.first,
                  let loaded = try store.load(id: header.workspaceID) else {
                throw SessionEntryError.unresolvedSavedWorkspace
            }
            guard !loaded.recoveredFromPrevious else {
                throw SessionEntryError.recoveryRequired(header.workspaceID)
            }
            snapshot = loaded.snapshot
        } else {
            // An unrecorded scratchpad may be the session just pasted. Do not
            // create a competing recorded owner before its association is resolved.
            if try store.storedAnchors().contains(where: { $0.isActive && $0.anchor.noteID == noteID && $0.anchor.isUnrecorded }) {
                throw SessionEntryError.unresolvedSavedWorkspace
            }
            guard context.registry.unresolved.isEmpty else {
                throw SessionEntryError.unresolvedSavedWorkspace
            }
            snapshot = try context.createWorkspace(range: selected,
                observation: document.snapshot.observationID, store: store)
        }
        return PreparedSession(snapshot: snapshot, context: context,
            association: try context.association(for: snapshot.anchor.sessionID), note: document.snapshot)
    }
}
