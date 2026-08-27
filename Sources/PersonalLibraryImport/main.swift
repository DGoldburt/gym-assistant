import Foundation
import GymAssistantCore

private struct ReviewDocument: Codable {
    let sourceHash: String
    let sourceRecords: Int
    let consolidatedObservations: Int
    let occurrences: Int
    let exactReuse: Int
    let items: [ReviewItem]
}

private struct ReviewItem: Codable {
    let id: String
    let name: String
    let occurrenceCount: Int
    let sourceCount: Int
    let sourceSamples: [String]
    let candidates: [Candidate]
}

private struct Candidate: Codable {
    let targetKind: String
    let targetID: String
    let name: String
    let evidence: String
    let linkAllowed: Bool
}

private struct ExtractionAudit: Decodable {
    let sourceHashBeforeReview: String
    let decisions: [ExtractionAuditDecision]

    enum CodingKeys: String, CodingKey {
        case sourceHashBeforeReview = "source_sha256_before_review"
        case decisions
    }
}

private struct ExtractionAuditDecision: Codable {
    let rowID: Int
    let decision: String
    let original: ExtractionAuditOriginal
    let wording: String?

    enum CodingKeys: String, CodingKey {
        case rowID = "row_id"
        case decision, original, wording
    }
}

private struct ExtractionAuditOriginal: Codable {
    let observedName: String

    enum CodingKeys: String, CodingKey {
        case observedName = "observed_name_verbatim"
    }
}

private struct FeedbackPacket: Codable {
    let schemaVersion: Int
    let generatedAt: String
    let sourceHash: String
    let extractionAuditHash: String
    let reconciliation: FeedbackReconciliation
    let extractionDecisions: [FeedbackExtractionDecision]
    let observations: [FeedbackObservation]
    let skippedObservationIDs: [String]
}

private struct FeedbackReconciliation: Codable {
    let sourceRecords: Int
    let consolidatedObservations: Int
    let occurrences: Int
    let databaseObservations: Int
    let databaseOccurrences: Int
    let extractionDecisions: Int
    let mappedExtractionDecisions: Int
    let unmappedExtractionRowIDs: [Int]
}

private struct FeedbackExtractionDecision: Codable {
    let rowID: Int
    let decision: String
    let observationIDs: [String]
}

private struct FeedbackObservation: Codable {
    let id: String
    let observedName: String
    let occurrenceCount: Int
    let status: String
    let resolvedExerciseID: String?
    let evidenceSnapshot: String
    let extractionAuditRowIDs: [Int]
    let initialCandidates: [Candidate]
    let occurrences: [FeedbackOccurrence]
}

private struct FeedbackOccurrence: Codable {
    let sourceReference: String
    let evidence: String
    let occurrenceCount: Int
}

private func usage() {
    print("Usage:")
    print("  swift run PersonalLibraryImport prepare <source.csv> <live.sqlite> <private-output-directory> <review-fragment.html> <expected-sha256>")
    print("  swift run PersonalLibraryImport ingest <source.csv> <destination.sqlite> <expected-sha256>")
    print("  swift run PersonalLibraryImport feedback <review-data.json> <extraction-audit.json> <database.sqlite> <private-output.json>")
}

if CommandLine.arguments.count == 6, CommandLine.arguments[1] == "feedback" {
    let reviewDataURL = URL(fileURLWithPath: CommandLine.arguments[2])
    let extractionAuditURL = URL(fileURLWithPath: CommandLine.arguments[3])
    let databaseURL = URL(fileURLWithPath: CommandLine.arguments[4])
    let outputURL = URL(fileURLWithPath: CommandLine.arguments[5])
    do {
        let decoder = JSONDecoder()
        let review = try decoder.decode(ReviewDocument.self, from: Data(contentsOf: reviewDataURL))
        let audit = try decoder.decode(ExtractionAudit.self, from: Data(contentsOf: extractionAuditURL))
        let service = ExerciseIdentityReviewService(library: try ExerciseLibrary(databaseURL: databaseURL))
        let ingestionReference = "personal-library:\(review.sourceHash)"
        let records = try service.feedbackRecords().filter {
            $0.observation.source.reference == ingestionReference
        }
        let normalizer = BasicExerciseNameNormalizer()
        var observationIDsByNormalizedName: [String: [String]] = [:]
        for record in records {
            let normalized = try normalizer.normalize(record.observation.observedName)
            observationIDsByNormalizedName[normalized, default: []].append(record.observation.id.rawValue)
        }

        var extractionDecisions: [FeedbackExtractionDecision] = []
        var auditRowsByObservationID: [String: [Int]] = [:]
        var unmappedRows: [Int] = []
        for decision in audit.decisions {
            let names = extractionNames(for: decision)
            let observationIDs = try names.flatMap { name in
                observationIDsByNormalizedName[try normalizer.normalize(name)] ?? []
            }.reduce(into: [String]()) { result, id in
                if !result.contains(id) { result.append(id) }
            }
            if decision.decision != "not_exercise", observationIDs.isEmpty {
                unmappedRows.append(decision.rowID)
            }
            for id in observationIDs {
                auditRowsByObservationID[id, default: []].append(decision.rowID)
            }
            extractionDecisions.append(.init(
                rowID: decision.rowID,
                decision: decision.decision,
                observationIDs: observationIDs.sorted()
            ))
        }

        let reviewItemsByID = Dictionary(uniqueKeysWithValues: review.items.map { ($0.id, $0) })
        let observations = records.map { record in
            FeedbackObservation(
                id: record.observation.id.rawValue,
                observedName: record.observation.observedName,
                occurrenceCount: record.observation.occurrenceCount,
                status: record.status.rawValue,
                resolvedExerciseID: record.resolvedExerciseID?.rawValue.uuidString,
                evidenceSnapshot: record.evidenceSnapshot,
                extractionAuditRowIDs: (auditRowsByObservationID[record.observation.id.rawValue] ?? []).sorted(),
                initialCandidates: reviewItemsByID[record.observation.id.rawValue]?.candidates ?? [],
                occurrences: record.occurrences.map {
                    .init(
                        sourceReference: $0.sourceReference,
                        evidence: $0.evidence,
                        occurrenceCount: $0.occurrenceCount
                    )
                }
            )
        }
        let packet = FeedbackPacket(
            schemaVersion: 1,
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            sourceHash: review.sourceHash,
            extractionAuditHash: audit.sourceHashBeforeReview,
            reconciliation: .init(
                sourceRecords: review.sourceRecords,
                consolidatedObservations: review.consolidatedObservations,
                occurrences: review.occurrences,
                databaseObservations: observations.count,
                databaseOccurrences: observations.reduce(0) { $0 + $1.occurrenceCount },
                extractionDecisions: audit.decisions.count,
                mappedExtractionDecisions: audit.decisions.count - unmappedRows.count,
                unmappedExtractionRowIDs: unmappedRows.sorted()
            ),
            extractionDecisions: extractionDecisions.sorted { $0.rowID < $1.rowID },
            observations: observations,
            skippedObservationIDs: observations.filter { $0.status == "deferred" }.map(\.id).sorted()
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(packet).write(to: outputURL, options: .atomic)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o600],
            ofItemAtPath: outputURL.path
        )
        print("Extractor feedback packet")
        print("source hash: \(packet.sourceHash)")
        print("observations: \(packet.reconciliation.databaseObservations)")
        print("occurrences: \(packet.reconciliation.databaseOccurrences)")
        print("extraction decisions: \(packet.reconciliation.extractionDecisions)")
        print("mapped extraction decisions: \(packet.reconciliation.mappedExtractionDecisions)")
        print("unmapped extraction decisions: \(packet.reconciliation.unmappedExtractionRowIDs.count)")
        print("skipped observations: \(packet.skippedObservationIDs.count)")
        exit(0)
    } catch {
        print("Unable to create extractor feedback packet: \(error)")
        exit(2)
    }
}

if CommandLine.arguments.count == 5, CommandLine.arguments[1] == "ingest" {
    let sourceURL = URL(fileURLWithPath: CommandLine.arguments[2])
    let databaseURL = URL(fileURLWithPath: CommandLine.arguments[3])
    let expectedHash = CommandLine.arguments[4]
    do {
        let source = try PersonalLibraryCSVAdapter().parse(data: Data(contentsOf: sourceURL))
        guard source.sourceHash == expectedHash else {
            print("Source hash mismatch; refusing to ingest")
            exit(3)
        }
        let library = try ExerciseLibrary(databaseURL: databaseURL)
        let service = ExerciseIdentityReviewService(library: library)
        let (ingestion, observations) = source.ingestion()
        let report = try service.ingest(ingestion, observations: observations)
        print("Personal library ingestion")
        print("source hash: \(source.sourceHash)")
        print("observations: \(report.observationCount)")
        print("occurrences: \(report.occurrenceCount)")
        print("already ingested: \(report.alreadyIngested)")
        print("review queue: \(try service.reviewQueue().count)")
        exit(0)
    } catch {
        print("Unable to ingest personal-library source: \(error)")
        exit(2)
    }
}

guard CommandLine.arguments.count == 7, CommandLine.arguments[1] == "prepare" else {
    usage()
    exit(2)
}

let sourceURL = URL(fileURLWithPath: CommandLine.arguments[2])
let liveDatabaseURL = URL(fileURLWithPath: CommandLine.arguments[3])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[4], isDirectory: true)
let fragmentURL = URL(fileURLWithPath: CommandLine.arguments[5])
let expectedHash = CommandLine.arguments[6]

do {
    let sourceData = try Data(contentsOf: sourceURL)
    let source = try PersonalLibraryCSVAdapter().parse(data: sourceData)
    guard source.sourceHash == expectedHash else {
        print("Source hash mismatch; refusing to prepare review")
        exit(3)
    }
    guard !FileManager.default.fileExists(atPath: outputURL.path) else {
        print("Private output directory already exists; choose a fresh directory")
        exit(3)
    }
    try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)
    let scratchURL = outputURL.appendingPathComponent("scratch-library.sqlite")
    try FileManager.default.copyItem(at: liveDatabaseURL, to: scratchURL)

    let library = try ExerciseLibrary(databaseURL: scratchURL)
    let service = ExerciseIdentityReviewService(library: library)
    let (ingestion, ingestedObservations) = source.ingestion()
    _ = try service.ingest(ingestion, observations: ingestedObservations)
    var exactReuse = 0
    var items: [ReviewItem] = []

    for observation in source.observations {
        switch try service.prepare(observationID: observation.id) {
        case .alreadyResolved:
            exactReuse += 1
        case .review(_, let existingCandidates):
            let candidates: [Candidate] = existingCandidates.map { candidate in
                .init(
                    targetKind: "existingExercise",
                    targetID: candidate.exerciseID.rawValue.uuidString,
                    name: candidate.preferredName,
                    evidence: candidate.evidence.map(evidenceText).joined(separator: ", "),
                    linkAllowed: candidate.linkAllowed
                )
            }

            items.append(.init(
                id: observation.id.rawValue,
                name: observation.observedName,
                occurrenceCount: observation.occurrenceCount,
                sourceCount: observation.sources.count,
                sourceSamples: observation.sources.prefix(2).map {
                    "\($0.note): \(String($0.line.prefix(240)))"
                },
                candidates: candidates
            ))
        }
    }

    let document = ReviewDocument(
        sourceHash: source.sourceHash,
        sourceRecords: source.recordCount,
        consolidatedObservations: source.observations.count,
        occurrences: source.occurrenceCount,
        exactReuse: exactReuse,
        items: items
    )
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let documentData = try encoder.encode(document)
    try documentData.write(to: outputURL.appendingPathComponent("review-data.json"), options: .atomic)
    let interfaceDocument = ReviewDocument(
        sourceHash: document.sourceHash,
        sourceRecords: document.sourceRecords,
        consolidatedObservations: document.consolidatedObservations,
        occurrences: document.occurrences,
        exactReuse: document.exactReuse,
        items: Array(document.items.prefix(150))
    )
    let interfaceData = try encoder.encode(interfaceDocument)
    try reviewFragment(documentJSON: String(decoding: interfaceData, as: UTF8.self))
        .write(to: fragmentURL, atomically: true, encoding: .utf8)

    print("Personal library dry-run preparation")
    print("source hash: \(source.sourceHash)")
    print("source records: \(source.recordCount)")
    print("consolidated observations: \(source.observations.count)")
    print("occurrences: \(source.occurrenceCount)")
    print("exact existing reuse: \(exactReuse)")
    print("human review required: \(items.count)")
    print("live database writes: 0")
} catch {
    print("Unable to prepare personal-library review: \(error)")
    exit(2)
}

private func evidenceText(_ evidence: ExerciseReviewEvidence) -> String {
    switch evidence {
    case .conservativeTransformation(let detail): return "transformation: \(detail)"
    case .lexicalSimilarity(let score): return String(format: "lexical %.3f", score)
    case .prescriptionDifference(let detail): return "prescription: \(detail)"
    case .identityConflict(let detail): return "identity conflict: \(detail)"
    }
}

private func extractionNames(for decision: ExtractionAuditDecision) -> [String] {
    guard decision.decision != "not_exercise" else { return [] }
    let source = decision.wording?.trimmingCharacters(in: .whitespacesAndNewlines)
    let text = source?.isEmpty == false ? source! : decision.original.observedName
    return text.split(separator: "|", omittingEmptySubsequences: true)
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
}

private func reviewFragment(documentJSON: String) -> String {
    let safeJSON = documentJSON.replacingOccurrences(of: "</", with: "<\\/")
    return """
    <div id="exercise10-import-review">
      <style>
        #exercise10-import-review{font:15px -apple-system,BlinkMacSystemFont,sans-serif;color:var(--foreground);max-width:780px;margin:auto}
        #exercise10-import-review .top{display:flex;justify-content:space-between;gap:12px;align-items:center;margin-bottom:14px}
        #exercise10-import-review .progress{font-variant-numeric:tabular-nums;color:var(--muted-foreground)}
        #exercise10-import-review .name{font-size:26px;font-weight:650;margin:14px 0 8px}
        #exercise10-import-review .meta,#exercise10-import-review .source{color:var(--muted-foreground);margin:6px 0}
        #exercise10-import-review .candidate{width:100%;text-align:left;padding:10px;margin:6px 0;border:1px solid var(--border);border-radius:8px;background:transparent;color:var(--foreground)}
        #exercise10-import-review .candidate[aria-selected="true"]{outline:2px solid var(--ring)}
        #exercise10-import-review .candidate:disabled{opacity:.55}
        #exercise10-import-review .evidence{display:block;font-size:12px;color:var(--muted-foreground);margin-top:3px}
        #exercise10-import-review .actions{display:flex;gap:8px;flex-wrap:wrap;margin-top:16px}
        #exercise10-import-review .actions button{padding:9px 13px;border:1px solid var(--border);border-radius:8px;background:var(--secondary);color:var(--secondary-foreground)}
        #exercise10-import-review .summary{margin-top:12px;color:var(--muted-foreground)}
      </style>
      <div class="top"><strong>Exercise import review</strong><span class="progress" id="eir-progress"></span></div>
      <div class="name" id="eir-name"></div>
      <div class="meta" id="eir-meta"></div>
      <div id="eir-sources"></div>
      <div id="eir-candidates"></div>
      <div class="actions">
        <button id="eir-link">Link selected (L)</button>
        <button id="eir-create">Create exact name (C)</button>
        <button id="eir-defer">Defer (D)</button>
        <button id="eir-back">Back (←)</button>
        <button id="eir-copy">Copy decisions JSON</button>
        <button id="eir-send">Send completed batch to Codex</button>
      </div>
      <div class="summary" id="eir-summary"></div>
      <script type="application/json" id="eir-data">\(safeJSON)</script>
      <script>
        (()=>{const root=document.getElementById('exercise10-import-review');const data=JSON.parse(root.querySelector('#eir-data').textContent);const key='exercise10-import-'+data.sourceHash;let decisions=JSON.parse(localStorage.getItem(key)||'{}');let index=0,selected=0;const q=s=>root.querySelector(s);function pending(){return data.items.filter(x=>!decisions[x.id])}function save(){localStorage.setItem(key,JSON.stringify(decisions))}function render(){const p=pending();if(!p.length){q('#eir-name').textContent='Review complete';q('#eir-meta').textContent='Copy the decisions JSON and send it to Codex for validation and an evolving-library recalculation.';q('#eir-sources').innerHTML='';q('#eir-candidates').innerHTML='';}else{index=Math.min(index,p.length-1);const x=p[index];selected=Math.min(selected,Math.max(0,x.candidates.length-1));q('#eir-name').textContent=x.name;q('#eir-meta').textContent=`${x.occurrenceCount} occurrences · ${x.sourceCount} source records`;q('#eir-sources').innerHTML=x.sourceSamples.map(s=>`<div class="source"></div>`).join('');[...q('#eir-sources').children].forEach((e,i)=>e.textContent=x.sourceSamples[i]);q('#eir-candidates').innerHTML='';x.candidates.forEach((c,i)=>{const b=document.createElement('button');b.className='candidate';b.disabled=!c.linkAllowed;b.setAttribute('aria-selected',i===selected);b.textContent=c.name;const s=document.createElement('span');s.className='evidence';s.textContent=c.evidence;b.appendChild(s);b.onclick=()=>{selected=i;render()};q('#eir-candidates').appendChild(b)});}const counts=Object.values(decisions).reduce((a,d)=>(a[d.decision]=(a[d.decision]||0)+1,a),{});q('#eir-progress').textContent=`${Object.keys(decisions).length}/${data.items.length}`;q('#eir-summary').textContent=`Link ${counts.link||0} · Create ${counts.create||0} · Defer ${counts.defer||0} · Pending ${p.length}`;q('#eir-link').disabled=!p.length||!p[index].candidates[selected]?.linkAllowed}
        function decide(decision){const p=pending();if(!p.length)return;const x=p[index];const value={decision};if(decision==='link'){const c=x.candidates[selected];if(!c||!c.linkAllowed)return;value.targetKind=c.targetKind;value.targetID=c.targetID;value.targetName=c.name}decisions[x.id]=value;save();selected=0;render()}
        q('#eir-link').onclick=()=>decide('link');q('#eir-create').onclick=()=>decide('create');q('#eir-defer').onclick=()=>decide('defer');q('#eir-back').onclick=()=>{const ids=Object.keys(decisions);if(!ids.length)return;delete decisions[ids[ids.length-1]];save();render()};q('#eir-copy').onclick=async()=>navigator.clipboard.writeText(JSON.stringify({sourceHash:data.sourceHash,decisions},null,2));q('#eir-send').onclick=async()=>{if(pending().length)return;if(window.openai?.sendFollowUpMessage)await window.openai.sendFollowUpMessage({title:'Submit review batch',prompt:'Exercise 10 import review batch decisions:\n'+JSON.stringify({sourceHash:data.sourceHash,decisions})})};root.addEventListener('keydown',e=>{if(e.key==='ArrowDown'){selected++;render()}else if(e.key==='ArrowUp'){selected=Math.max(0,selected-1);render()}else if(e.key.toLowerCase()==='l')decide('link');else if(e.key.toLowerCase()==='c')decide('create');else if(e.key.toLowerCase()==='d')decide('defer');else if(e.key==='ArrowLeft')q('#eir-back').click()});root.tabIndex=0;root.focus();render()})();
      </script>
    </div>
    """
}
