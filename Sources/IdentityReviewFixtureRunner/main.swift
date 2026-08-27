import Darwin
import Foundation
import GymAssistantCore

private struct Document: Decodable {
    let cases: [Fixture]
}

private struct Fixture: Decodable {
    let id: String
    let observation: String
    let candidate: String
    let expectedDisposition: String
}

guard CommandLine.arguments.count == 2 else {
    print("Usage: swift run IdentityReviewFixtureRunner <fixture-json-path>")
    exit(2)
}

let directory = FileManager.default.temporaryDirectory
    .appendingPathComponent("gym-assistant-review-report-\(UUID().uuidString)", isDirectory: true)

do {
    let document = try JSONDecoder().decode(
        Document.self,
        from: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
    )
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }

    var passes = 0
    print("Identity review fixture report")
    for item in document.cases {
        let databaseURL = directory.appendingPathComponent("\(item.id).sqlite")
        let library = try ExerciseLibrary(databaseURL: databaseURL)
        _ = try library.createExercise(preferredName: item.candidate)
        let service = ExerciseIdentityReviewService(library: library)
        let observationID = ExerciseObservationID(rawValue: item.id)
        try service.stage(.init(
            id: observationID,
            observedName: item.observation,
            source: .init(adapter: "fixture", reference: item.id),
            occurrenceCount: 1
        ))

        guard case .review(_, let candidates) = try service.prepare(observationID: observationID),
              let candidate = candidates.first(where: { $0.preferredName == item.candidate }) else {
            print("FAIL \(item.id): candidate was not surfaced")
            continue
        }
        let actual = candidate.linkAllowed ? "linkableWithConfirmation" : "identityConflict"
        let evidence = candidate.evidence.map { String(describing: $0) }.joined(separator: ", ")
        if actual == item.expectedDisposition {
            passes += 1
            print("PASS \(item.id): \(actual) [\(evidence)]")
        } else {
            print("FAIL \(item.id): expected \(item.expectedDisposition), got \(actual) [\(evidence)]")
        }
    }
    print("total: \(document.cases.count)")
    print("passes: \(passes)")
    print("candidate-caused identity writes: 0")
    exit(passes == document.cases.count ? 0 : 1)
} catch {
    print("Unable to run identity-review fixtures: \(error)")
    exit(2)
}
