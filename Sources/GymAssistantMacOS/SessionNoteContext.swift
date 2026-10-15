import AppKit
import GymAssistantWorkspace

/// App composition retains one instance per NoteID. Every saved anchor for that
/// note participates, whether its window is visible, closed or not opened yet.
@MainActor public final class SessionNoteContext {
    public let noteID: NoteID
    public let monitor: NotesRefreshCoordinator
    public private(set) var registry: SessionAssociationRegistry
    public private(set) var sourceDocument: ProgramDocument?
    public private(set) var richText: NSAttributedString?
    public private(set) var failure: String?
    private var listener: Task<Void, Never>?
    private var visible: Set<WorkspaceID> = []
    private var subscribers: [WorkspaceID: @MainActor () -> Void] = [:]
    private var cachedHTML: String?
    private var appliedSequence: UInt64 = 0
    // A failed save may have reached disk before reporting failure. Do not let
    // a later Notes read clear this uncertainty; reopening reloads durable owners.
    private var persistenceFailure: String?

    public init(noteID: NoteID, anchors: [SessionAnchor], reader: any NotesContextReading) throws {
        self.noteID = noteID
        registry = try SessionAssociationRegistry(noteID: noteID, anchors: anchors)
        monitor = NotesRefreshCoordinator(noteID: noteID, reader: reader)
        listener = Task { [weak self, monitor] in
            for await observation in await monitor.observations() {
                guard !Task.isCancelled, let self else { return }
                self.consume(observation)
            }
        }
    }
    deinit { listener?.cancel() }
    public func subscribe(workspace: WorkspaceID, update: @escaping @MainActor () -> Void) { subscribers[workspace] = update }
    public func unsubscribe(workspace: WorkspaceID) { subscribers.removeValue(forKey: workspace) }
    public func releaseSetAside(_ snapshot: WorkspaceSnapshot) {
        guard !snapshot.isActive, snapshot.anchor.noteID == noteID else { return }
        registry.release(snapshot.anchor.sessionID)
        publish()
    }
    private func publish() { for subscriber in subscribers.values { subscriber() } }

    public func setVisible(_ value: Bool, workspace: WorkspaceID) async {
        let wasEmpty = visible.isEmpty
        if value { visible.insert(workspace) } else { visible.remove(workspace) }
        await monitor.setVisible(!visible.isEmpty)
        if value && wasEmpty { _ = try? await refresh(for: .resume) }
    }
    public func reactivate() async { await monitor.idleTick(reactivated: true) }

    @discardableResult public func refresh(for reason: NotesRefreshCoordinator.Reason) async throws -> ProgramDocument {
        do {
            _ = try await monitor.validate(for: reason)
            try Task.checkCancellation()
            consume(await monitor.observation())
            guard failure == nil, let sourceDocument else {
                throw WorkspaceError.staleAssociation
            }
            return sourceDocument
        } catch {
            failure = persistenceFailure ?? "Notes could not be verified: \(error)"; publish(); throw error
        }
    }

    private func consume(_ observation: NotesObservationState) {
        guard observation.sequence > appliedSequence else { return }
        appliedSequence = observation.sequence
        if let snapshot = observation.snapshot { accept(snapshot) }
        if let failure = observation.failure { self.failure = "Notes unavailable: \(failure)" }
        publish()
    }

    public func association(for id: SessionID) throws -> SessionAssociation {
        guard failure == nil, let association = registry.mappings[id],
              association.observationID == sourceDocument?.snapshot.observationID else { throw WorkspaceError.staleAssociation }
        return association
    }

    public func confirm(session: SessionID, range: SourceRange, observation: UUID) throws -> SessionAnchor {
        guard failure == nil, let document = sourceDocument, document.snapshot.observationID == observation else {
            throw WorkspaceError.staleAssociation
        }
        try registry.confirm(sessionID: session, range: range, in: document)
        guard let anchor = registry.anchor(for: session) else { throw SessionAssociationError.unknownSession }
        publish()
        return anchor
    }

    /// Called after the entry flow's fresh read and explicit region choice.
    /// Validation and persistence precede publication of ownership; failed saves
    /// cannot leave a phantom owner in the shared context.
    public func createWorkspace(range: SourceRange, observation: UUID, store: WorkspaceSnapshotStore) throws -> WorkspaceSnapshot {
        guard failure == nil, let document = sourceDocument, let richText,
              document.snapshot.observationID == observation else { throw WorkspaceError.staleAssociation }
        let evidence = try document.evidence(in: range)
        let anchor = SessionAnchor(noteID: noteID, recordedHeading: evidence.paragraphs.first?.label ?? "Session",
            baselineText: evidence.text, sourceEvidence: evidence)
        var candidateRegistry = registry
        try candidateRegistry.register(anchor, range: range, in: document)
        let rich = richText.attributedSubstring(from: range.nsRange)
        var snapshot = WorkspaceSnapshot(anchor: anchor, text: rich.string, richTextArchive: try RichTextArchive.encode(rich))
        snapshot.boundaryProtection = BoundaryEditProtection(sourceRange: range)
        try persist(snapshot, store: store)
        registry = candidateRegistry
        publish()
        return snapshot
    }

    /// Promote only a fully saved, exactly inserted addition. Persist first, then
    /// publish ownership. Failure leaves the existing editor and identity intact.
    public func associateInsertedSession(_ snapshot: WorkspaceSnapshot, observation: UUID,
                                         store: WorkspaceSnapshotStore) throws -> WorkspaceSnapshot {
        guard failure == nil, let document = sourceDocument,
              document.snapshot.observationID == observation,
              snapshot.anchor.isUnrecorded, snapshot.anchor.noteID == noteID,
              let saved = try store.load(id: snapshot.workspaceID), !saved.recoveredFromPrevious,
              saved.snapshot == snapshot else { throw WorkspaceError.staleAssociation }
        let rich = try RichTextArchive.decode(snapshot.richTextArchive)
        let scratchpad = try ProgramDocumentReader.document(snapshot: NoteSnapshot(id: noteID, text: snapshot.text), richText: rich)
        guard case .verified(let range) = UnrecordedSessionAssociation.evaluate(anchor: snapshot.anchor,
            scratchpad: SessionSourceEvidence(paragraphs: scratchpad.paragraphs), document: document) else {
            throw WorkspaceError.staleAssociation
        }
        let evidence = try document.evidence(in: range)
        return try recordAssociation(snapshot, evidence: evidence, range: range, certain: true, document: document, store: store)
    }

    /// The coach confirms identity only. Keep scratchpad content unchanged even
    /// when it differs from the selected Notes section; protect uncertain edits.
    public func confirmInsertedSession(_ snapshot: WorkspaceSnapshot, range: SourceRange,
                                       observation: UUID, store: WorkspaceSnapshotStore) throws -> WorkspaceSnapshot {
        guard failure == nil, let document = sourceDocument,
              document.snapshot.observationID == observation, snapshot.anchor.isUnrecorded,
              snapshot.anchor.noteID == noteID,
              let saved = try store.load(id: snapshot.workspaceID), !saved.recoveredFromPrevious,
              saved.snapshot == snapshot else { throw WorkspaceError.staleAssociation }
        let evidence = try document.evidence(in: range)
        return try recordAssociation(snapshot, evidence: evidence, range: range, certain: false, document: document, store: store)
    }

    private func recordAssociation(_ snapshot: WorkspaceSnapshot, evidence: SessionSourceEvidence, range: SourceRange,
                                   certain: Bool, document: ProgramDocument, store: WorkspaceSnapshotStore) throws -> WorkspaceSnapshot {
        var candidate = snapshot
        candidate.anchor.recordingState = .recorded
        candidate.anchor.recordedHeading = evidence.paragraphs.first?.label ?? snapshot.anchor.recordedHeading
        candidate.anchor.baselineText = evidence.text
        candidate.anchor.sourceEvidence = evidence
        candidate.anchor.unrecordedOrigin = nil
        candidate.boundaryProtection = BoundaryEditProtection(sourceRange: range)
        if !certain { candidate.boundaryProtection?.markUncertain(currentLength: (candidate.text as NSString).length) }
        candidate.revision += 1
        var proposedRegistry = registry
        try proposedRegistry.register(candidate.anchor, range: range, in: document)
        try persist(candidate, store: store)
        registry = proposedRegistry
        publish()
        return candidate
    }

    /// Commit the controller's complete proposed edit only against the exact
    /// observation it previewed. Never advance the confirmed Notes baseline.
    public func commitBoundary(_ snapshot: WorkspaceSnapshot, range: SourceRange,
                               observation: UUID, store: WorkspaceSnapshotStore) throws {
        guard failure == nil, let document = sourceDocument,
              document.snapshot.observationID == observation,
              snapshot.anchor.noteID == noteID else { throw WorkspaceError.staleAssociation }
        let session = snapshot.anchor.sessionID
        guard let original = registry.anchor(for: session),
              let saved = try store.load(id: snapshot.workspaceID), !saved.recoveredFromPrevious,
              saved.snapshot.anchor.sessionID == session, saved.snapshot.anchor.noteID == noteID else {
            throw SessionAssociationError.unknownSession
        }
        guard registry.duplicateLabels.isEmpty,
              registry.unresolved.subtracting([session]).isEmpty else {
            throw SessionAssociationError.unresolvedOwnership
        }
        guard snapshot.anchor.baselineText == original.baselineText,
              snapshot.revision > saved.snapshot.revision,
              snapshot.anchor.sourceEvidence == (try document.evidence(in: range)),
              snapshot.boundaryProtection?.sourceRange == range else { throw WorkspaceError.invalidSnapshot }
        var candidateRegistry = registry
        try candidateRegistry.confirm(sessionID: session, range: range, in: document)
        try persist(snapshot, store: store)
        registry = candidateRegistry
        publish()
    }

    private func persist(_ snapshot: WorkspaceSnapshot, store: WorkspaceSnapshotStore) throws {
        do { try store.save(snapshot) }
        catch {
            persistenceFailure = "Workspace save could not be confirmed. Keep the scratchpad open; resolve local recovery before changing session ownership."
            failure = persistenceFailure
            publish()
            throw error
        }
    }

    private func accept(_ snapshot: NoteSnapshot) {
        guard persistenceFailure == nil else { failure = persistenceFailure; return }
        if sourceDocument?.snapshot.observationID == snapshot.observationID { failure = nil; return }
        do {
            let document: ProgramDocument
            if cachedHTML == snapshot.html, let previous = sourceDocument {
                let canonical = NoteSnapshot(id: snapshot.id, observationID: snapshot.observationID,
                    text: previous.snapshot.text, html: snapshot.html, modifiedAt: snapshot.modifiedAt)
                document = try ProgramDocument(snapshot: canonical, paragraphs: previous.paragraphs)
            } else {
                let imported = try ProgramDocumentReader.read(snapshot)
                document = imported.0; richText = imported.1; cachedHTML = snapshot.html
            }
            try registry.observe(document)
            sourceDocument = document; failure = nil
        } catch {
            failure = "Notes formatting could not be read without losing information. Existing scratchpad is preserved."
        }
    }
}
