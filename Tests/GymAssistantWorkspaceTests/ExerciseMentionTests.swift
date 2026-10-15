import Foundation
import Testing
@testable import GymAssistantWorkspace

@Suite("Exercise mention evidence") struct ExerciseMentionTests {
    @Test func validatesUnicodeBoundsTextAndOverlapWithoutSearchingProse() {
        let text = "🏋️ Try SL RDL then a reach."
        let range = (text as NSString).range(of: "SL RDL")
        let valid = ExerciseMention(text: "SL RDL", range: .init(location: range.location, length: range.length))
        let bad = [ExerciseMention(text: "RDL", range: .init(location: range.location, length: 3)),
                   ExerciseMention(text: "missing", range: .init(location: 999, length: 9)),
                   ExerciseMention(text: "x", range: .init(location: -1, length: 1))]
        #expect(ExerciseMention.validated(bad + [valid, valid], in: text) == [valid])
        #expect(ProgrammingResponse(requestID: UUID(), text: text).exerciseMentions.isEmpty)
    }

    @Test func legacyMessagesDecodeWithoutMentionsAndNewEvidenceRoundTrips() throws {
        var message = ConversationMessage(requestID: UUID(), conversationID: ConversationID(), role: .assistant,
            text: "SL RDL", status: .complete, scratchpadRevision: 0, observationID: UUID())
        let old = try JSONEncoder().encode(message)
        #expect(!String(decoding: old, as: UTF8.self).contains("exerciseMentions"))
        #expect(try JSONDecoder().decode(ConversationMessage.self, from: old).exerciseMentions == nil)
        message.exerciseMentions = [.init(text: "SL RDL", range: .init(location: 0, length: 6))]
        #expect(try JSONDecoder().decode(ConversationMessage.self, from: JSONEncoder().encode(message)) == message)
    }
}
