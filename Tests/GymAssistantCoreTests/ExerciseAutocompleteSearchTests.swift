import Foundation
import Testing
@testable import GymAssistantCore

@Suite("Exercise autocomplete search")
struct ExerciseAutocompleteSearchTests {
    @Test("Ranks exact, whole-name prefix, and ordered token-prefix evidence")
    func transparentRanking() throws {
        let fixture = try SearchFixture()
        _ = try fixture.add("Squat")
        _ = try fixture.add("Front Squat")
        _ = try fixture.add("Barbell Front Squat")
        _ = try fixture.add("Floor Press")
        _ = try fixture.add("Dumbbell Floor Press")

        #expect(try fixture.search.search("squat").map(\.preferredName).prefix(2) == ["Squat", "Front Squat"])
        #expect(try fixture.search.search("front").map(\.preferredName).prefix(2) == ["Front Squat", "Barbell Front Squat"])
        #expect(try fixture.search.search("floor pr").map(\.preferredName).prefix(2) == ["Floor Press", "Dumbbell Floor Press"])
    }

    @Test("Confirmed aliases retrieve one exercise and remain available for insertion")
    func aliasRetrievalAndDeduplication() throws {
        let fixture = try SearchFixture()
        let rdl = try fixture.add("Single-Leg Romanian Deadlift", aliases: ["SL RDL", "Single Leg RDL"])

        let results = try fixture.search.search("sl")
        #expect(results.count == 1)
        #expect(results.first?.exerciseID == rdl.exercise.id)
        #expect(results.first?.preferredName == "Single-Leg Romanian Deadlift")
        #expect(results.first?.matchedName == "SL RDL")
        #expect(results.first?.matchedNameIsPreferred == false)
        #expect(results.first?.aliases == ["Single Leg RDL", "SL RDL"])
    }

    @Test("Multiple matching aliases still produce one stable result")
    func multipleAliasesDeduplicate() throws {
        let fixture = try SearchFixture()
        _ = try fixture.add("Dumbbell Floor Press", aliases: ["DB Floor", "DB Floor Press"])

        let first = try fixture.search.search("db")
        let second = try fixture.search.search("db")
        #expect(first.count == 1)
        #expect(first == second)
        #expect(first.first?.matchedName == "DB Floor")
    }

    @Test("Fuzzy spelling is lowest-priority search evidence")
    func fuzzySpelling() throws {
        let fixture = try SearchFixture()
        _ = try fixture.add("Copenhagen Plank")
        _ = try fixture.add("Coppen Press")

        let results = try fixture.search.search("coppen")
        #expect(results.map(\.preferredName).prefix(2) == ["Coppen Press", "Copenhagen Plank"])
        #expect(results.first?.matchKind == .namePrefix)
        #expect(results.dropFirst().first?.matchKind == .fuzzy)
    }

    @Test("Protected modifier conflicts are excluded from fuzzy results")
    func protectedFuzzyConflict() throws {
        let fixture = try SearchFixture()
        _ = try fixture.add("Long-Lever Copenhagen Plank")

        #expect(try fixture.search.search("Short-Lever Copenhagn Plank").isEmpty)
    }

    @Test("Empty and unrelated queries return no stored result")
    func noResultQueries() throws {
        let fixture = try SearchFixture()
        _ = try fixture.add("Front Squat")
        _ = try fixture.add("Tall Kneeling Bottoms-Up KB Press")

        #expect(try fixture.search.search("").isEmpty)
        #expect(try fixture.search.search("   ").isEmpty)
        #expect(try fixture.search.search("Novel March").isEmpty)
        #expect(try fixture.search.search("test").isEmpty)
    }

    @Test("Short fuzzy queries require strong edit evidence")
    func shortFuzzyQueries() throws {
        let fixture = try SearchFixture()
        _ = try fixture.add("Squat")
        _ = try fixture.add("Copenhagen Plank")

        let squatResults = try fixture.search.search("sqat")
        #expect(squatResults.map(\.preferredName) == ["Squat"])
        #expect(squatResults.first?.matchKind == .fuzzy)

        for query in ["c", "co", "cop", "copp", "coppe", "coppen"] {
            #expect(try fixture.search.search(query).contains {
                $0.preferredName == "Copenhagen Plank"
            })
        }
    }

    @Test("Search limit and tie ordering are deterministic")
    func deterministicLimit() throws {
        let fixture = try SearchFixture()
        _ = try fixture.add("Alpha Press")
        _ = try fixture.add("Beta Press")
        _ = try fixture.add("Gamma Press")

        let expected = ["Beta Press", "Alpha Press"]
        #expect(try fixture.search.search("press", limit: 2).map(\.preferredName) == expected)
        #expect(try fixture.search.search("press", limit: 2).map(\.preferredName) == expected)
        #expect(try fixture.search.search("press", limit: 0).isEmpty)
    }

    @Test("Cross-exercise ties use preferred display names rather than matched aliases")
    func preferredDisplayNameBreaksResultTie() throws {
        let fixture = try SearchFixture()
        _ = try fixture.add("Zulu Press", aliases: ["Able Alias"])
        _ = try fixture.add("Alpha Press", aliases: ["Zulu Alias"])

        #expect(try fixture.search.search("alias").map(\.preferredName) == ["Alpha Press", "Zulu Press"])
    }

    @Test("Every search path leaves the persisted library unchanged")
    func searchIsReadOnly() throws {
        let fixture = try SearchFixture()
        _ = try fixture.add("Dumbbell Floor Press", aliases: ["DB Floor Press"])
        _ = try fixture.add("Copenhagen Plank")
        let before = try fixture.library.allNames()

        _ = try fixture.search.search("db fl")
        _ = try fixture.search.search("coppen")
        _ = try fixture.search.search("Novel March")
        _ = try fixture.search.search("")

        #expect(try fixture.library.allNames() == before)
    }
}

private final class SearchFixture {
    let directoryURL: URL
    let library: ExerciseLibrary
    let search: ExerciseAutocompleteSearch

    init() throws {
        directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("gym-assistant-search-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        library = try ExerciseLibrary(databaseURL: directoryURL.appendingPathComponent("exercise-library.sqlite"))
        search = ExerciseAutocompleteSearch(library: library)
    }

    func add(_ preferredName: String, aliases: [String] = []) throws -> CreatedExercise {
        let created = try library.createExercise(preferredName: preferredName)
        for alias in aliases {
            _ = try library.addName(alias, to: created.exercise.id)
        }
        return created
    }

    deinit {
        try? FileManager.default.removeItem(at: directoryURL)
    }
}
