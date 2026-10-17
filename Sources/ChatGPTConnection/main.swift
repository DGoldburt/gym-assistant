import AppKit
import GymAssistantOpenAI
import GymAssistantWorkspace

@main struct ConnectionMain {
    static func main() async {
        guard CommandLine.arguments.count == 2,
              ["--connect", "--check-model", "--check-input-count", "--synthetic-trial", "--synthetic-single"].contains(CommandLine.arguments[1]) else {
            print("Use --connect to authorize Gym Assistant, or --check-model to verify 5.6 Terra availability. No inference is performed.")
            return
        }
        do {
            let connection = ChatGPTConnection()
            if ["--synthetic-trial", "--synthetic-single"].contains(CommandLine.arguments[1]) {
                do { try await runSyntheticTrial(connection, single: CommandLine.arguments[1] == "--synthetic-single") }
                catch {
                    print(await connection.trialDiagnostic)
                    print("Trial requests used: \(try await connection.trialRequestsUsed()) / 10.")
                    throw error
                }
                return
            }
            if CommandLine.arguments[1] == "--check-input-count" {
                let count = try await connection.checkSyntheticInputCount()
                print("Synthetic preflight counted \(count) input tokens. No inference was run.")
                return
            }
            if CommandLine.arguments[1] == "--connect" {
                print("Opening Continue with ChatGPT. Approve Gym Assistant in your browser. No note or programming content is sent.")
                fflush(stdout)
                try await connection.connect { url in await MainActor.run { NSWorkspace.shared.open(url) } }
                print("Gym Assistant's connection is saved in macOS Keychain.")
            }
            try await connection.verifySelectedModel()
            print("ChatGPT plan usage is authorized and gpt-5.6-terra is listed. No inference request has run.")
        } catch {
            if let failure = error as? AssistantFailure {
                print(failure.userMessage); exit(1)
            }
            // Never interpolate arbitrary errors: provider errors can contain sensitive values.
            let message: String
            switch error as? ChatGPTConnectionError {
            case .inputCountingUnavailable(let status): message = "Input-count preflight unavailable (HTTP \(status)). No inference was run."
            case .declined: message = "Sign-in was declined. No inference was run."
            case .modelUnavailable: message = "5.6 Terra is not listed for this connection. No model was substituted."
            case .planPermissionMissing: message = "ChatGPT plan usage is not authorized. Use --connect to authorize it."
            case .busy: message = "Another Gym Assistant connection operation is running."
            case .timeout: message = "Sign-in timed out. Run --connect again to retry."
            case .invalidIdentity: message = "The returned identity could not be verified. Credentials were not accepted."
            case .storage: message = "Gym Assistant could not access or save its Keychain connection."
            case .browserUnavailable: message = "The browser could not be opened."
            default: message = "Connection could not be verified. No inference was run; retry sign-in when ready."
            }
            print(message)
            exit(1)
        }
    }

    static func runSyntheticTrial(_ connection: ChatGPTConnection, single: Bool) async throws {
        let note = NoteSnapshot(id: .init("synthetic-live-test"), text: "Synthetic client\nSession 1\nA1 Row\nA2 Split squat\n")
        var scratchpad = WorkspaceSnapshot(anchor: .init(noteID: note.id, recordedHeading: "Session 2", baselineText: "", recordingState: .unrecorded),
            text: "Session 2\nA1 Deadlift\nA2 Push-up\nB1 Press\nB2 undecided\n", richTextArchive: Data([1]))
        let profile = CoachingProfile(version: "synthetic-live-1", entries: [
            .init(wording: "Keep replies short; favor coordination challenges when appropriate.", source: "Synthetic trial preference", kind: .authored, confirmed: true)
        ])
        for question in ["Suggest one unloaded B2 exercise that complements this session. One sentence.",
                         "I have now changed B1 in the scratchpad. What is B1, and should we reconsider your B2 suggestion? Be brief."] {
            let request = try ProgramContextAssembler.assembleUnrecorded(note: note, workspace: scratchpad,
                profile: profile, question: question, maximumContextBytes: 100_000)
            let start = Date()
            let reply = try await connection.reply(to: request)
            print("Synthetic reply completed in \(Int(Date().timeIntervalSince(start)))s; validated exercise mentions: \(reply.exerciseMentions.count).")
            print(reply.text)
            if single { break }
            scratchpad.messages.append(.init(requestID: request.id, conversationID: request.conversationID,
                role: .coach, text: question, status: .complete, scratchpadRevision: scratchpad.revision, observationID: note.observationID))
            scratchpad.messages.append(.init(requestID: request.id, conversationID: request.conversationID,
                role: .assistant, text: reply.text, status: .complete, scratchpadRevision: scratchpad.revision, observationID: note.observationID))
            scratchpad.text = "Session 2\nA1 Deadlift\nA2 Push-up\nB1 Side plank\nB2 undecided\n"
            scratchpad.revision += 1
        }
        print("Trial requests used: \(try await connection.trialRequestsUsed()) / 10. No real Notes content was read or sent.")
    }
}
