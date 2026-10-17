import Foundation
import Testing
@testable import GymAssistantWorkspace

@Suite("Private coaching profile") struct CoachingProfileStoreTests {
    @Test func preservesEvidenceWithoutPromotingInferences() throws {
        let profile = CoachingProfile(version: "synthetic-1", entries: [
            .init(wording: "A tentative preference", source: "Synthetic source", kind: .inferred,
                  confirmed: false, scope: "One block", exceptions: ["Not a general rule"])
        ])
        #expect(try CoachingProfileStore.decode(JSONEncoder().encode(profile)) == profile)
    }
    @Test func refusesMissingMalformedEmptyAndOversizedProfiles() throws {
        #expect(throws: CoachingProfileLoadError.unavailable) {
            try CoachingProfileStore.load(from: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        }
        for profile in [CoachingProfile(version: "v1", entries: []),
                        CoachingProfile(version: " ", entries: [.init(wording: "x", source: "s", kind: .authored, confirmed: true)]),
                        CoachingProfile(version: "v1", entries: [.init(wording: "x", source: " ", kind: .authored, confirmed: true)])] {
            #expect(throws: CoachingProfileLoadError.invalid) { try CoachingProfileStore.decode(JSONEncoder().encode(profile)) }
        }
        #expect(throws: CoachingProfileLoadError.invalid) { try CoachingProfileStore.decode(Data("{}".utf8)) }
        #expect(throws: CoachingProfileLoadError.oversized) { try CoachingProfileStore.decode(Data(repeating: 32, count: 100_001)) }
    }
}
