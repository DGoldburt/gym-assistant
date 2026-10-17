import Foundation
import Testing
import Security
import CryptoKit
@testable import GymAssistantOpenAI

@Suite("ChatGPT connection security") struct ChatGPTAuthorizationTests {
    @Test func loopbackReceivesCallbackWithoutEchoingSecrets() async throws {
        let listener = try ChatGPTLoopbackListener()
        #expect(listener.redirect.host == "127.0.0.1")
        let worker = Task.detached { try listener.wait(timeout: 5) }
        let url = URL(string: listener.redirect.absoluteString + "?state=synthetic&code=secret-fixture&client_id=oaiapp_fixture")!
        let (data, response) = try await URLSession.shared.data(from: url)
        #expect((response as? HTTPURLResponse)?.statusCode == 200)
        #expect(!String(decoding: data, as: UTF8.self).contains("secret-fixture"))
        #expect(try await worker.value == url)
    }
    @Test func loopbackTimeoutAndCancellation() async throws {
        let listener = try ChatGPTLoopbackListener()
        #expect(throws: ChatGPTConnectionError.timeout) { try listener.wait(timeout: 0) }
        let worker = Task.detached { try listener.wait(timeout: 5) }
        worker.cancel()
        await #expect(throws: CancellationError.self) { try await worker.value }
    }
    private func attempt(client: String? = nil) throws -> ChatGPTAuthorizationAttempt {
        try .init(redirect: URL(string: "http://127.0.0.1:1455/auth/callback")!, hostID: "urn:uuid:synthetic", existingClientID: client)
    }
    private func callback(_ attempt: ChatGPTAuthorizationAttempt, extra: String = "") -> URL {
        URL(string: attempt.redirect.absoluteString + "?state=\(attempt.state)&code=synthetic-code&client_id=oaiapp_fixture" + extra)!
    }
    @Test func freshAuthorizationAndPKCE() throws {
        let first = try attempt(), second = try attempt()
        #expect(first.state != second.state && first.nonce != second.nonce && first.verifier != second.verifier)
        let query = URLComponents(url: first.authorizationURL, resolvingAgainstBaseURL: false)!.queryItems!
        let values = Dictionary(uniqueKeysWithValues: query.map { ($0.name, $0.value!) })
        #expect(values["client_id"] == "dynamic_agent_client")
        #expect(values["agent_name_hint"] == "Gym Assistant")
        #expect(values["code_challenge"] == Data(SHA256.hash(data: Data(first.verifier.utf8))).base64URL)
        #expect(!first.authorizationURL.absoluteString.contains(first.verifier))
        let returning = try attempt(client: "oaiapp_fixture")
        #expect(!returning.authorizationURL.absoluteString.contains("agent_name_hint"))
    }
    @Test func callbackBoundToStateOriginClientAndTime() throws {
        let a = try attempt()
        #expect(try a.validateCallback(callback(a)).clientID == "oaiapp_fixture")
        for bad in [callback(a, extra: "&state=duplicate"),
                    URL(string: callback(a).absoluteString.replacingOccurrences(of: "127.0.0.1", with: "localhost"))!,
                    URL(string: callback(a).absoluteString.replacingOccurrences(of: a.state, with: "wrong"))!,
                    URL(string: callback(a).absoluteString.replacingOccurrences(of: "oaiapp_fixture", with: "dynamic_agent_client"))!] {
            #expect(throws: ChatGPTConnectionError.invalidCallback) { try a.validateCallback(bad) }
        }
        #expect(throws: ChatGPTConnectionError.invalidCallback) { try a.validateCallback(callback(a), now: a.createdAt.addingTimeInterval(301)) }
        let returning = try attempt(client: "oaiapp_other")
        #expect(throws: ChatGPTConnectionError.invalidCallback) { try returning.validateCallback(callback(returning)) }
        let denied = URL(string: a.redirect.absoluteString + "?state=\(a.state)&error=access_denied")!
        #expect(throws: ChatGPTConnectionError.declined) { try a.validateCallback(denied) }
    }
    @Test func formEncodingDoesNotChangeCodeOrRedirect() throws {
        let a = try attempt()
        let body = String(data: a.exchangeBody(code: "a+b&c=d", clientID: "oaiapp_fixture"), encoding: .utf8)!
        #expect(body.contains("code=a%2Bb%26c%3Dd"))
        #expect(body.contains("redirect_uri=http%3A%2F%2F127.0.0.1%3A1455%2Fauth%2Fcallback"))
        #expect(!body.contains("client_secret"))
    }
    @Test func refreshPreservesOmittedScopesAndRotatesCredentials() throws {
        let old = ChatGPTCredentials(accessToken: "old", refreshToken: "old-refresh", idToken: "id",
            scopes: ["chatgpt.tokens.use.direct"], expiresAt: .distantPast)
        let renewed = TokenResponse(access_token: "new", refresh_token: "new-refresh", id_token: nil,
            token_type: "Bearer", expires_in: 3600, scope: nil)
        let value = try renewed.credentials(idToken: old.idToken, previous: old)
        #expect(value.refreshToken == "new-refresh" && value.scopes == old.scopes)
        let revoked = TokenResponse(access_token: "new", refresh_token: nil, id_token: nil,
            token_type: "Bearer", expires_in: 3600, scope: "openid")
        #expect(try !revoked.credentials(idToken: "id", previous: old).scopes.contains("chatgpt.tokens.use.direct"))
        let invalid = TokenResponse(access_token: "", refresh_token: nil, id_token: nil, token_type: "Bearer", expires_in: 3600, scope: nil)
        #expect(throws: ChatGPTConnectionError.invalidResponse) { try invalid.credentials(idToken: "id") }
    }
    @Test func signedIdentityAndClaimRejections() throws {
        let privateKey = try #require(SecKeyCreateRandomKey([kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits: 2048] as CFDictionary, nil))
        let publicKey = try #require(SecKeyCopyPublicKey(privateKey))
        let exported = try #require(SecKeyCopyExternalRepresentation(publicKey, nil)) as Data
        var index = 0
        func readDER() throws -> Data {
            guard index + 2 <= exported.count else { throw ChatGPTConnectionError.invalidIdentity }
            index += 1; var length = Int(exported[index]); index += 1
            if length > 127 {
                let count = length & 127; length = 0
                for _ in 0..<count { length = (length << 8) | Int(exported[index]); index += 1 }
            }
            let value = exported.subdata(in: index..<(index + length)); index += length
            return value
        }
        // Skip the sequence header, then read its two INTEGER children.
        index = 1
        let count = Int(exported[index]); index += count > 127 ? 1 + (count & 127) : 1
        let n = try readDER(), e = try readDER()
        let keys = try JSONSerialization.data(withJSONObject: ["keys": [["kty": "RSA", "kid": "fixture", "alg": "RS256", "n": n.base64URL, "e": e.base64URL]]])
        let now = Date()
        func token(_ change: [String: Any] = [:], algorithm: String = "RS256") throws -> String {
            var claims: [String: Any] = ["iss": "https://auth.openai.com", "sub": "synthetic-user",
                "aud": "oaiapp_fixture", "exp": now.addingTimeInterval(60).timeIntervalSince1970, "nonce": "expected"]
            claims.merge(change) { _, new in new }
            let header = try JSONSerialization.data(withJSONObject: ["alg": algorithm, "kid": "fixture"]).base64URL
            let body = try JSONSerialization.data(withJSONObject: claims).base64URL
            let input = header + "." + body
            let signature = try #require(SecKeyCreateSignature(privateKey, .rsaSignatureMessagePKCS1v15SHA256, Data(input.utf8) as CFData, nil)) as Data
            return input + "." + signature.base64URL
        }
        let good = try token()
        #expect(try ChatGPTIdentityVerifier.verify(good, keys: keys, clientID: "oaiapp_fixture", nonce: "expected", now: now).subject == "synthetic-user")
        for change: [String: Any] in [["iss": "https://wrong.example"], ["aud": "wrong"], ["nonce": "wrong"],
                                     ["exp": now.addingTimeInterval(-1).timeIntervalSince1970], ["sub": ""],
                                     ["aud": ["oaiapp_fixture", "other"]], ["azp": "wrong"]] {
            let bad = try token(change)
            #expect(throws: ChatGPTConnectionError.invalidIdentity) { try ChatGPTIdentityVerifier.verify(bad, keys: keys, clientID: "oaiapp_fixture", nonce: "expected", now: now) }
        }
        for bad in [try token(algorithm: "none"), good + "tampered", "invalid"] {
            #expect(throws: ChatGPTConnectionError.invalidIdentity) { try ChatGPTIdentityVerifier.verify(bad, keys: keys, clientID: "oaiapp_fixture", nonce: "expected", now: now) }
        }
    }
}
