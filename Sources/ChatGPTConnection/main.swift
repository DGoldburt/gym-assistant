import AppKit
import GymAssistantOpenAI

@main struct ConnectionMain {
    static func main() async {
        guard CommandLine.arguments.count == 2,
              ["--connect", "--check-model"].contains(CommandLine.arguments[1]) else {
            print("Use --connect to authorize Gym Assistant, or --check-model to verify 5.6 Terra availability. No inference is performed.")
            return
        }
        do {
            let connection = ChatGPTConnection()
            if CommandLine.arguments[1] == "--connect" {
                print("Opening Continue with ChatGPT. Approve Gym Assistant in your browser. No note or programming content is sent.")
                fflush(stdout)
                try await connection.connect { url in await MainActor.run { NSWorkspace.shared.open(url) } }
                print("Gym Assistant's connection is saved in macOS Keychain.")
            }
            try await connection.verifySelectedModel()
            print("ChatGPT plan usage is authorized and gpt-5.6-terra is listed. No inference request has run.")
        } catch {
            // Never interpolate arbitrary errors: provider errors can contain sensitive values.
            let message: String
            switch error as? ChatGPTConnectionError {
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
}
