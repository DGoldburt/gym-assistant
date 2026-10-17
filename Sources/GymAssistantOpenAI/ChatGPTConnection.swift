import Foundation
import Security
import Darwin

struct ChatGPTCredentials: Codable {
    let accessToken: String
    let refreshToken: String?
    let idToken: String
    let scopes: [String]
    let expiresAt: Date
}
struct ChatGPTRegistration: Codable {
    let clientID: String
    var identity: ChatGPTIdentity?
    var credentials: ChatGPTCredentials?
}
struct ChatGPTAccountState: Codable {
    var hostID = "urn:uuid:" + UUID().uuidString.lowercased()
    var registration: ChatGPTRegistration?
}

/// One app-owned Keychain item. This never opens Codex/ChatGPT credential stores.
struct ChatGPTKeychain {
    private var query: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: "GymAssistant.ChatGPT",
         kSecAttrAccount as String: "local-personal-connection-v1"]
    }
    func load() throws -> ChatGPTAccountState {
        var q = query; q[kSecReturnData as String] = true; q[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(q as CFDictionary, &result)
        if status == errSecItemNotFound { return ChatGPTAccountState() }
        guard status == errSecSuccess, let data = result as? Data,
              let state = try? JSONDecoder().decode(ChatGPTAccountState.self, from: data)
        else { throw ChatGPTConnectionError.storage }
        return state
    }
    func save(_ state: ChatGPTAccountState) throws {
        let data = try JSONEncoder().encode(state)
        let status = SecItemUpdate(query as CFDictionary, [kSecValueData: data] as CFDictionary)
        if status == errSecItemNotFound {
            var q = query; q[kSecValueData as String] = data
            q[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            guard SecItemAdd(q as CFDictionary, nil) == errSecSuccess else { throw ChatGPTConnectionError.storage }
        } else if status != errSecSuccess { throw ChatGPTConnectionError.storage }
    }
}

/// Cross-process exclusion avoids simultaneous registration and rotating-token races.
final class ChatGPTConnectionLock {
    private let fd: Int32
    init() throws {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("GymAssistant", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        fd = open(root.appendingPathComponent("chatgpt-connection.lock").path, O_CREAT | O_RDWR | O_NOFOLLOW, S_IRUSR | S_IWUSR)
        guard fd >= 0 else { throw ChatGPTConnectionError.storage }
        guard flock(fd, LOCK_EX | LOCK_NB) == 0 else { close(fd); throw ChatGPTConnectionError.busy }
    }
    deinit { flock(fd, LOCK_UN); close(fd) }
}

/// Avoid forwarding credentials or authorization POSTs to redirects.
private final class NoRedirect: NSObject, URLSessionTaskDelegate, Sendable {
    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest,
                    completionHandler: @escaping @Sendable (URLRequest?) -> Void) { completionHandler(nil) }
}

public actor ChatGPTConnection {
    private let keychain = ChatGPTKeychain()
    private let session: URLSession
    public init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.httpCookieStorage = nil; config.urlCredentialStorage = nil; config.urlCache = nil
        session = URLSession(configuration: config, delegate: NoRedirect(), delegateQueue: nil)
    }
    /// Authorization only. No Notes access, inference, or model-usage request.
    public func connect(openBrowser: @Sendable (URL) async -> Bool) async throws {
        let lock = try ChatGPTConnectionLock()
        defer { withExtendedLifetime(lock) {} }
        var state = try keychain.load()
        try keychain.save(state) // Persist host before opening the browser.
        let listener = try ChatGPTLoopbackListener()
        let attempt = try ChatGPTAuthorizationAttempt(redirect: listener.redirect, hostID: state.hostID,
            existingClientID: state.registration?.clientID)
        guard await openBrowser(attempt.authorizationURL) else { throw ChatGPTConnectionError.browserUnavailable }
        let worker = Task.detached { try listener.wait() }
        let callback = try await withTaskCancellationHandler {
            try await worker.value
        } onCancel: { worker.cancel() }
        try Task.checkCancellation()
        let result = try attempt.validateCallback(callback)
        if state.registration == nil {
            state.registration = ChatGPTRegistration(clientID: result.clientID)
            try keychain.save(state) // Issued client survives an expired code or failed exchange.
        }
        let data = try await postToken(attempt.exchangeBody(code: result.code, clientID: result.clientID))
        let tokens: TokenResponse
        do { tokens = try JSONDecoder().decode(TokenResponse.self, from: data) }
        catch { throw ChatGPTConnectionError.invalidResponse }
        guard let jwt = tokens.id_token else { throw ChatGPTConnectionError.invalidIdentity }
        let keys = try await get("https://auth.openai.com/.well-known/jwks.json")
        let identity = try ChatGPTIdentityVerifier.verify(jwt, keys: keys, clientID: result.clientID, nonce: attempt.nonce)
        if let previous = state.registration?.identity {
            guard previous.issuer == identity.issuer, previous.subject == identity.subject
            else { throw ChatGPTConnectionError.invalidIdentity }
        }
        let credentials = try tokens.credentials(idToken: jwt)
        state.registration?.identity = identity
        state.registration?.credentials = credentials
        try keychain.save(state)
        guard credentials.scopes.contains("chatgpt.tokens.use.direct") else { throw ChatGPTConnectionError.planPermissionMissing }
    }

    /// Returns only whether the selected model is listed. Tokens never leave this actor.
    public func verifySelectedModel() async throws {
        let lock = try ChatGPTConnectionLock()
        defer { withExtendedLifetime(lock) {} }
        var state = try keychain.load()
        guard let registration = state.registration, registration.identity != nil,
              var credentials = registration.credentials else { throw ChatGPTConnectionError.planPermissionMissing }
        if credentials.expiresAt.timeIntervalSinceNow < 60 {
            guard let refresh = credentials.refreshToken else { throw ChatGPTConnectionError.planPermissionMissing }
            let response = try await postToken(formData(["grant_type": "refresh_token", "client_id": registration.clientID,
                "refresh_token": refresh, "resource": "https://api.openai.com/v1"]))
            let tokens: TokenResponse
            do { tokens = try JSONDecoder().decode(TokenResponse.self, from: response) }
            catch { throw ChatGPTConnectionError.invalidResponse }
            credentials = try tokens.credentials(idToken: credentials.idToken, previous: credentials)
            state.registration?.credentials = credentials
            try keychain.save(state)
        }
        guard credentials.scopes.contains("chatgpt.tokens.use.direct") else { throw ChatGPTConnectionError.planPermissionMissing }
        let data = try await get("https://api.openai.com/v1/models", token: credentials.accessToken)
        struct Catalog: Decodable {
            struct Model: Decodable { let slug: String; let visibility: String }
            let models: [Model]
        }
        guard let catalog = try? JSONDecoder().decode(Catalog.self, from: data) else { throw ChatGPTConnectionError.invalidResponse }
        guard catalog.models.contains(where: { $0.slug == "gpt-5.6-terra" && $0.visibility == "list" })
        else { throw ChatGPTConnectionError.modelUnavailable }
    }

    private func get(_ address: String, token: String? = nil) async throws -> Data {
        var request = URLRequest(url: URL(string: address)!)
        if let token { request.setValue("Bearer " + token, forHTTPHeaderField: "Authorization") }
        return try await perform(request)
    }
    private func postToken(_ data: Data) async throws -> Data {
        var request = URLRequest(url: URL(string: "https://auth.openai.com/api/accounts/oauth/token")!)
        request.httpMethod = "POST"; request.httpBody = data
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        return try await perform(request)
    }
    private func perform(_ request: URLRequest) async throws -> Data {
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200, data.count <= 2_000_000
            else { throw ChatGPTConnectionError.invalidResponse }
            return data
        } catch is CancellationError { throw CancellationError() }
        catch let error as ChatGPTConnectionError { throw error }
        catch { throw ChatGPTConnectionError.network }
    }
}

struct TokenResponse: Decodable {
    let access_token: String
    let refresh_token: String?
    let id_token: String?
    let token_type: String
    let expires_in: Double
    let scope: String?
    func credentials(idToken: String, previous: ChatGPTCredentials? = nil) throws -> ChatGPTCredentials {
        guard token_type.lowercased() == "bearer", !access_token.isEmpty,
              expires_in.isFinite, expires_in > 0 else { throw ChatGPTConnectionError.invalidResponse }
        let scopes = scope.map { $0.split(separator: " ").map(String.init) } ?? previous?.scopes ?? []
        return ChatGPTCredentials(accessToken: access_token, refreshToken: refresh_token ?? previous?.refreshToken,
            idToken: idToken, scopes: scopes, expiresAt: Date().addingTimeInterval(expires_in))
    }
}
