// Candidate shared freshness policy only. Injected reader/clock, no Notes or API.
import Foundation
import CryptoKit

struct BodyObservation: Equatable { let body: String; let date: Int }
final class Reader {
    var value: BodyObservation
    var available = true
    var metadataReads = 0
    var bodyReads = 0
    init(_ value: BodyObservation) { self.value = value }
    func metadata() -> Int? { metadataReads += 1; return available ? value.date : nil }
    func body() -> BodyObservation? { bodyReads += 1; return available ? value : nil }
}
enum Consumer: Hashable { case chat, diff, wholeCopy, resume }
struct Ticket: Hashable { let id: Int; let consumer: Consumer }
enum Freshness: Equatable { case current, unavailable }
struct Result { let freshness: Freshness; let observation: BodyObservation? }
final class Coordinator {
    let reader: Reader
    var cache: BodyObservation?
    var parses = 0
    var diffBuilds = 0
    var tokenizationPasses = 0
    var modelCalls = 0
    var visible = true
    var queued: [Ticket] = []
    var active: [Ticket] = []
    var pendingBody: BodyObservation?
    var results: [Ticket: Result] = [:]
    var nextID = 0
    init(_ reader: Reader) { self.reader = reader }
    func idleTick() {
        guard visible else { return }
        if let date = reader.metadata(), date != cache?.date { _ = request(.resume) }
    }
    func request(_ consumer: Consumer) -> Ticket {
        nextID += 1
        let ticket = Ticket(id: nextID, consumer: consumer)
        queued.append(ticket)
        return ticket
    }
    func beginBodyRead() {
        guard active.isEmpty, !queued.isEmpty else { return }
        active = queued; queued = []
        // Candidate: body validation for ALL safety consumers because date collisions
        // were observed. Requests arriving after capture do not join this older read.
        _ = reader.metadata()
        pendingBody = reader.body()
    }
    func completeBodyRead() {
        guard !active.isEmpty else { return }
        if let observation = pendingBody {
            if observation.body != cache?.body { parses += 1; diffBuilds += 1 }
            cache = observation
            for ticket in active { results[ticket] = Result(freshness: .current, observation: observation) }
        } else {
            for ticket in active { results[ticket] = Result(freshness: .unavailable, observation: cache) }
        }
        active = []; pendingBody = nil
    }
    func runQueuedCycle() { beginBodyRead(); completeBodyRead() }
}
var count = 0
var failures = 0
func check(_ condition: @autoclosure () -> Bool, _ name: String) {
    count += 1; let passed = condition(); failures += passed ? 0 : 1
    print("\(passed ? "PASS" : "FAIL") \(name)")
}
let large = (1...1000).map { "Synthetic program line \($0)" }.joined(separator: "\n")
let reader = Reader(BodyObservation(body: large, date: 100))
let monitor = Coordinator(reader)
_ = monitor.request(.resume); monitor.runQueuedCycle()
check(reader.bodyReads == 1 && monitor.parses == 1, "Initial large-note observation cached once")
let metadataBefore = reader.metadataReads
for _ in 0..<20 { monitor.idleTick() }
check(reader.metadataReads - metadataBefore == 20 && reader.bodyReads == 1, "20 unchanged shared idle ticks perform metadata reads only")
check(monitor.parses == 1 && monitor.diffBuilds == 1 && monitor.tokenizationPasses == 0 && monitor.modelCalls == 0, "Idle monitor does no new parsing, diff, tokenization or model work")
reader.value = BodyObservation(body: large + "\nSame-date coach edit", date: 100)
let chat = monitor.request(.chat)
let diff = monitor.request(.diff)
let copy = monitor.request(.wholeCopy)
monitor.runQueuedCycle()
check(reader.bodyReads == 2, "Concurrent chat/diff/whole-copy share one body validation")
check([chat, diff, copy].allSatisfy { monitor.results[$0]?.observation?.body == reader.value.body }, "Equal metadata cannot hide edit from any safety consumer")
check(monitor.parses == 2 && monitor.diffBuilds == 2, "Changed body processes once across consumers")
let unchangedChat = monitor.request(.chat)
monitor.runQueuedCycle()
check(reader.bodyReads == 3 && monitor.results[unchangedChat]?.freshness == .current, "Later safety request revalidates body, not just metadata")
check(monitor.parses == 2 && monitor.diffBuilds == 2, "Unchanged safety body read reuses parsed/diff caches")
let earlier = monitor.request(.diff)
monitor.beginBodyRead()
let capturedBody = reader.value.body
reader.value = BodyObservation(body: capturedBody + "\nLater edit", date: 100)
let later = monitor.request(.wholeCopy)
monitor.completeBodyRead()
check(monitor.results[earlier]?.observation?.body == capturedBody && monitor.results[later] == nil, "Request after body capture cannot claim older in-flight observation")
monitor.runQueuedCycle()
check(monitor.results[later]?.observation?.body == reader.value.body, "Later consumer waits for its covering read")
let cached = monitor.cache
reader.available = false
let offline = monitor.request(.wholeCopy); monitor.runQueuedCycle()
check(monitor.results[offline]?.freshness == .unavailable && monitor.cache == cached, "Failure preserves last-known data without claiming current")
check(monitor.results[offline]?.observation == cached, "Copy may retain cached context only with explicit unverified status")
monitor.visible = false
let hiddenCount = reader.metadataReads
for _ in 0..<20 { monitor.idleTick() }
check(reader.metadataReads == hiddenCount, "Hidden monitor makes no timer reads")
reader.available = true; monitor.visible = true
let resumed = monitor.request(.resume); monitor.runQueuedCycle()
check(monitor.results[resumed]?.freshness == .current, "Resume explicitly validates current body")
check(monitor.modelCalls == 0 && monitor.tokenizationPasses == 0, "No provider activity in any monitoring or copy path")
print("RESULT \(count - failures)/\(count) candidate freshness assertions passed; injected simulation, not production scheduling or native performance")
exit(failures == 0 ? 0 : 1)
