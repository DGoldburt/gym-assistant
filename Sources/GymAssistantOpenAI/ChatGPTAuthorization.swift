import Foundation
import CryptoKit
import Security

/// Intentionally contains no raw provider response, token, callback or URL in errors.
public enum ChatGPTConnectionError: Error, Equatable {
    case invalidCallback, declined, invalidIdentity, invalidResponse, storage, network, busy, timeout
    case planPermissionMissing, modelUnavailable, browserUnavailable
    case inputCountingUnavailable(Int)
}

extension Data {
    var base64URL: String {
        base64EncodedString().replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
    }
    init?(base64URL: String) {
        let text = base64URL.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        self.init(base64Encoded: text + String(repeating: "=", count: (4 - text.count % 4) % 4))
    }
}

public struct ChatGPTAuthorizationAttempt: Sendable {
    let state: String
    let nonce: String
    let verifier: String
    let redirect: URL
    let existingClientID: String?
    let createdAt: Date
    private let hostID: String
    public init(redirect: URL, hostID: String, existingClientID: String? = nil) throws {
        guard redirect.scheme == "http", redirect.host == "127.0.0.1", redirect.port != nil,
              redirect.path == "/auth/callback", redirect.query == nil, redirect.fragment == nil,
              !hostID.isEmpty else { throw ChatGPTConnectionError.invalidCallback }
        func random() throws -> String {
            var bytes = [UInt8](repeating: 0, count: 32)
            guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess
            else { throw ChatGPTConnectionError.invalidResponse }
            return Data(bytes).base64URL
        }
        state = try random(); nonce = try random(); verifier = try random()
        self.redirect = redirect; self.hostID = hostID; self.existingClientID = existingClientID
        createdAt = Date()
    }
    public var authorizationURL: URL {
        var components = URLComponents(string: "https://auth.openai.com/api/accounts/authorize")!
        var parameters = ["client_id": existingClientID ?? "dynamic_agent_client",
            "ext_agent_host_id": hostID, "response_type": "code", "redirect_uri": redirect.absoluteString,
            "scope": "openid profile email offline_access resource.invoke chatgpt.tokens.use.direct",
            "resource": "https://api.openai.com/v1", "state": state, "nonce": nonce,
            "code_challenge_method": "S256", "code_challenge": Data(SHA256.hash(data: Data(verifier.utf8))).base64URL]
        if existingClientID == nil { parameters["agent_name_hint"] = "Gym Assistant" }
        components.queryItems = parameters.sorted { $0.key < $1.key }.map { URLQueryItem(name: $0.key, value: $0.value) }
        return components.url!
    }
    public func validateCallback(_ url: URL, now: Date = Date()) throws -> (code: String, clientID: String) {
        guard now.timeIntervalSince(createdAt) >= 0, now.timeIntervalSince(createdAt) < 300,
              url.scheme == redirect.scheme, url.host == redirect.host, url.port == redirect.port,
              url.path == redirect.path, url.fragment == nil, url.user == nil, url.password == nil,
              let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
        else { throw ChatGPTConnectionError.invalidCallback }
        var values: [String: String] = [:]
        for item in items {
            guard values[item.name] == nil, let value = item.value else { throw ChatGPTConnectionError.invalidCallback }
            values[item.name] = value
        }
        guard values["state"] == state else { throw ChatGPTConnectionError.invalidCallback }
        if values["error"] != nil { throw ChatGPTConnectionError.declined }
        guard let code = values["code"], !code.isEmpty,
              let client = values["client_id"] ?? existingClientID,
              client.hasPrefix("oaiapp_"), client.count > 7,
              existingClientID == nil || client == existingClientID
        else { throw ChatGPTConnectionError.invalidCallback }
        return (code, client)
    }
    func exchangeBody(code: String, clientID: String) -> Data {
        formData(["grant_type": "authorization_code", "client_id": clientID, "code": code,
                  "code_verifier": verifier, "redirect_uri": redirect.absoluteString,
                  "resource": "https://api.openai.com/v1"])
    }
}

func formData(_ fields: [String: String]) -> Data {
    let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~"))
    return Data(fields.sorted { $0.key < $1.key }.map {
        $0.key.addingPercentEncoding(withAllowedCharacters: allowed)! + "=" +
        $0.value.addingPercentEncoding(withAllowedCharacters: allowed)!
    }.joined(separator: "&").utf8)
}

struct ChatGPTIdentity: Codable, Equatable {
    let issuer: String
    let subject: String
    let email: String?
}

/// Verifies RS256 with Apple's Security implementation; unsupported algorithms fail closed.
enum ChatGPTIdentityVerifier {
    struct KeySet: Decodable { let keys: [Key] }
    struct Key: Decodable {
        let kty: String; let kid: String; let n: String?; let e: String?
        let alg: String?; let use: String?
    }
    private struct Header: Decodable { let alg: String; let kid: String; let crit: [String]? }
    private struct Claims: Decodable {
        let iss: String; let sub: String; let exp: Double; let nonce: String
        let aud: Audience; let azp: String?; let email: String?
        enum Audience: Decodable {
            case one(String), many([String])
            init(from decoder: any Decoder) throws {
                let c = try decoder.singleValueContainer()
                if let text = try? c.decode(String.self) { self = .one(text) }
                else { self = .many(try c.decode([String].self)) }
            }
            var values: [String] { switch self { case .one(let v): [v]; case .many(let v): v } }
        }
    }
    static func verify(_ jwt: String, keys: Data, clientID: String, nonce: String, now: Date = Date()) throws -> ChatGPTIdentity {
        do {
            let parts = jwt.split(separator: ".", omittingEmptySubsequences: false)
            guard parts.count == 3, let headerData = Data(base64URL: String(parts[0])),
                  let body = Data(base64URL: String(parts[1])), let signature = Data(base64URL: String(parts[2]))
            else { throw ChatGPTConnectionError.invalidIdentity }
            let header = try JSONDecoder().decode(Header.self, from: headerData)
            guard header.alg == "RS256", header.crit == nil || header.crit == [] else { throw ChatGPTConnectionError.invalidIdentity }
            let matches = try JSONDecoder().decode(KeySet.self, from: keys).keys.filter {
                $0.kid == header.kid && $0.kty == "RSA" && ($0.alg == nil || $0.alg == "RS256") && ($0.use == nil || $0.use == "sig")
            }
            guard matches.count == 1, let n = matches[0].n.flatMap(Data.init(base64URL:)),
                  let e = matches[0].e.flatMap(Data.init(base64URL:)), n.count >= 256, !e.isEmpty
            else { throw ChatGPTConnectionError.invalidIdentity }
            let keyBytes = der(tag: 0x30, content: integer(n) + integer(e))
            guard let key = SecKeyCreateWithData(keyBytes as CFData,
                [kSecAttrKeyType: kSecAttrKeyTypeRSA, kSecAttrKeyClass: kSecAttrKeyClassPublic] as CFDictionary, nil),
                SecKeyVerifySignature(key, .rsaSignatureMessagePKCS1v15SHA256,
                    Data((parts[0] + "." + parts[1]).utf8) as CFData, signature as CFData, nil)
            else { throw ChatGPTConnectionError.invalidIdentity }
            let claims = try JSONDecoder().decode(Claims.self, from: body)
            guard claims.iss == "https://auth.openai.com", !claims.sub.isEmpty,
                  claims.exp.isFinite, claims.exp > now.timeIntervalSince1970,
                  claims.nonce == nonce, claims.aud.values.contains(clientID),
                  (claims.aud.values.count == 1 || claims.azp == clientID),
                  (claims.azp == nil || claims.azp == clientID)
            else { throw ChatGPTConnectionError.invalidIdentity }
            return ChatGPTIdentity(issuer: claims.iss, subject: claims.sub, email: claims.email)
        } catch { throw ChatGPTConnectionError.invalidIdentity }
    }
    private static func integer(_ value: Data) -> Data {
        var bytes = Data(value.drop(while: { $0 == 0 }))
        if bytes.isEmpty { bytes = Data([0]) }
        if bytes[bytes.startIndex] & 0x80 != 0 { bytes.insert(0, at: bytes.startIndex) }
        return der(tag: 0x02, content: bytes)
    }
    private static func der(tag: UInt8, content: Data) -> Data {
        var length = content.count; var encoded: [UInt8] = []
        repeat { encoded.insert(UInt8(length & 255), at: 0); length >>= 8 } while length > 0
        let prefix = content.count < 128 ? [UInt8(content.count)] : [0x80 | UInt8(encoded.count)] + encoded
        return Data([tag] + prefix) + content
    }
}
