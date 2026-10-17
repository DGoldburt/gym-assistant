import Foundation
import Testing
import GymAssistantWorkspace
@testable import GymAssistantOpenAI

@Suite("Subscription response contract") struct SubscriptionResponseTests {
    @Test func trialLedgerPersistsAndRefusesReplayAndEleventhAttempt() throws {
        var ledger = SubscriptionTrialLedger()
        let first = UUID()
        try ledger.reserve(first)
        let stored = try JSONEncoder().encode(ledger)
        ledger = try JSONDecoder().decode(SubscriptionTrialLedger.self, from: stored)
        #expect(throws: SubscriptionFailure.trialLimit) { try ledger.reserve(first) }
        for _ in 1..<10 { try ledger.reserve(UUID()) }
        #expect(throws: SubscriptionFailure.trialLimit) { try ledger.reserve(UUID()) }
        #expect(ledger.submitted.count == 10)
    }
    @Test func oldKeychainRecordDoesNotLoseRegistration() throws {
        let state = try JSONDecoder().decode(ChatGPTAccountState.self, from: Data("{\"hostID\":\"synthetic\"}".utf8))
        #expect(state.hostID == "synthetic" && state.trialLedger == nil)
    }
    @Test func payloadUsesApprovedModelAndOnlySupportedFields() throws {
        let note = NoteSnapshot(id: .init("synthetic"), text: "Session 1\nA1 Coach choice\n")
        let snapshot = WorkspaceSnapshot(anchor: .init(noteID: note.id, recordedHeading: "Session 2", baselineText: "", recordingState: .unrecorded),
            text: "Session 2\nB2 undecided", richTextArchive: Data([1]))
        let request = try ProgramContextAssembler.assembleUnrecorded(note: note, workspace: snapshot,
            profile: .init(version: "test", entries: [.init(wording: "Keep replies short", source: "synthetic", kind: .authored, confirmed: true)]),
            question: "What should B2 be?", maximumContextBytes: 10_000)
        let payload = try SubscriptionPayload(request)
        let json = try #require(JSONSerialization.jsonObject(with: payload.encoded()) as? [String: Any])
        #expect(Set(json.keys) == ["model", "store", "stream", "reasoning", "instructions", "input"])
        #expect(json["model"] as? String == "gpt-5.6-terra")
        #expect(json["store"] as? Bool == false && json["stream"] as? Bool == true)
        #expect((json["reasoning"] as? [String: String])?["effort"] == "medium")
        #expect(payload.input.last?.content == request.question)
        #expect(payload.input.first?.content.contains("Coach choice") == true)
        #expect(payload.input.first?.content.contains("confirmed") == true)
        #expect(!payload.input.contains(where: { $0.role == "system" }))
        try payload.validateTrialSize()
        var large = snapshot
        large.text = String(repeating: "é", count: 60_000)
        let oversized = try ProgramContextAssembler.assembleUnrecorded(note: note, workspace: large,
            profile: request.profile, question: request.question, maximumContextBytes: 1_000_000)
        #expect(throws: SubscriptionFailure.inputLimit) { try SubscriptionPayload(oversized).validateTrialSize() }
    }
    private func completed(text: String = "reply", type: String = "message") throws -> String {
        let event: [String: Any] = ["type": "response.completed", "response": ["status": "completed",
            "output": [["type": type, "role": "assistant", "status": "completed", "content": [["type": "output_text", "text": text]]]],
            "usage": ["input_tokens": 20, "output_tokens": 10]]]
        return String(decoding: try JSONSerialization.data(withJSONObject: event), as: UTF8.self)
    }
    @Test func requiresTerminalCompletionNotDeltasOrDone() throws {
        var stream = SubscriptionStream()
        try stream.line("data: {\"type\":\"response.output_text.delta\",\"delta\":\"partial\"}")
        try stream.line("")
        try stream.line("data: [DONE]")
        #expect(throws: SubscriptionFailure.incomplete) { try stream.finish() }
        var successful = SubscriptionStream()
        try successful.line("event: response.completed")
        try successful.line("data: " + completed())
        try successful.line("")
        #expect(try successful.finish() == "reply")
        #expect(successful.inputTokens == 20 && successful.outputTokens == 10)
        var byteStream = SubscriptionStream()
        let wire = "event: response.completed\r\ndata: " + (try completed(text: "🏋️ reply")) + "\r\n\r\n"
        for byte in wire.utf8 { try byteStream.byte(byte) }
        #expect(try byteStream.finish() == "🏋️ reply")
    }
    @Test func rejectsLateFailureMalformedAndToolOutput() throws {
        var limited = SubscriptionStream()
        try limited.line("data: {\"type\":\"response.output_text.delta\",\"delta\":\"partial\"}")
        try limited.line("")
        try limited.line("data: {\"type\":\"response.failed\",\"response\":{\"error\":{\"code\":\"subscription_sharing_usage_limit_exceeded\"}}}")
        #expect(throws: SubscriptionFailure.usageLimit) { try limited.line("") }
        for raw in ["not json", try completed(type: "function_call"), try completed(text: " ")] {
            var stream = SubscriptionStream()
            try stream.line("data: " + raw)
            #expect(throws: SubscriptionFailure.invalidResponse) { try stream.finish() }
        }
    }
    @Test func usageUnavailableIsNotAnExhaustedAllowance() throws {
        for raw in [
            "{\"type\":\"response.failed\",\"response\":{\"error\":{\"code\":\"subscription_sharing_usage_unavailable\"}}}",
            "{\"type\":\"error\",\"code\":\"subscription_sharing_usage_unavailable\"}"
        ] {
            var stream = SubscriptionStream()
            try stream.line("data: " + raw)
            #expect(throws: SubscriptionFailure.usageUnavailable) { try stream.line("") }
        }
        #expect(AssistantFailure.usageUnavailable.userMessage != AssistantFailure.usageLimit.userMessage)
        #expect(AssistantFailure.usageUnavailable.userMessage.contains("could not check"))
    }
    @Test func providerDiagnosticsOnlyExposeKnownProtocolCodes() throws {
        for (code, expected) in [
            ("subscription_sharing_user_unavailable", SubscriptionFailure.providerCode("subscription_sharing_user_unavailable")),
            ("private arbitrary text", SubscriptionFailure.provider)
        ] {
            var stream = SubscriptionStream()
            try stream.line("data: {\"type\":\"response.failed\",\"response\":{\"error\":{\"code\":\"\(code)\",\"message\":\"private text\"}}}")
            #expect(throws: expected) { try stream.line("") }
        }
    }
    @Test func mentionsHaveValidatedUTF16RangesAndNoIdentity() throws {
        let id = UUID()
        let response = try SubscriptionReply.decode("{\"text\":\"🏋️ Try SL RDL, then SL RDL again.\",\"exercise_names\":[\"SL RDL\",\"invented name\"]}", requestID: id)
        #expect(response.requestID == id && response.exerciseMentions.count == 2)
        for mention in response.exerciseMentions {
            #expect((response.text as NSString).substring(with: mention.range.nsRange) == "SL RDL")
        }
        #expect(throws: SubscriptionFailure.invalidResponse) { try SubscriptionReply.decode("partial", requestID: id) }
    }
}
