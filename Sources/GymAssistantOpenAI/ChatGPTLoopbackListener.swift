import Foundation
import Darwin

/// Immutable socket owner. Exactly one worker calls wait(); no tokens are returned to the browser.
final class ChatGPTLoopbackListener: @unchecked Sendable {
    private let fd: Int32
    let redirect: URL
    init() throws {
        let socketFD = socket(AF_INET, SOCK_STREAM, 0)
        guard socketFD >= 0 else { throw ChatGPTConnectionError.network }
        var address = sockaddr_in()
        address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        address.sin_family = sa_family_t(AF_INET)
        address.sin_addr.s_addr = inet_addr("127.0.0.1")
        let bound = withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { bind(socketFD, $0, socklen_t(MemoryLayout<sockaddr_in>.size)) }
        }
        guard bound == 0, listen(socketFD, 4) == 0 else { close(socketFD); throw ChatGPTConnectionError.network }
        var length = socklen_t(MemoryLayout<sockaddr_in>.size)
        let named = withUnsafeMutablePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { getsockname(socketFD, $0, &length) }
        }
        guard named == 0 else { close(socketFD); throw ChatGPTConnectionError.network }
        fd = socketFD
        redirect = URL(string: "http://127.0.0.1:\(UInt16(bigEndian: address.sin_port))/auth/callback")!
    }
    deinit { close(fd) }
    func wait(timeout: TimeInterval = 300) throws -> URL {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            try Task.checkCancellation()
            var descriptor = pollfd(fd: fd, events: Int16(POLLIN), revents: 0)
            guard poll(&descriptor, 1, 1000) > 0 else { continue }
            let connection = accept(fd, nil, nil)
            guard connection >= 0 else { continue }
            defer { close(connection) }
            var noSignal: Int32 = 1
            setsockopt(connection, SOL_SOCKET, SO_NOSIGPIPE, &noSignal, socklen_t(MemoryLayout<Int32>.size))
            var readTimeout = timeval(tv_sec: 2, tv_usec: 0)
            setsockopt(connection, SOL_SOCKET, SO_RCVTIMEO, &readTimeout, socklen_t(MemoryLayout<timeval>.size))
            var bytes = Data(); var buffer = [UInt8](repeating: 0, count: 4096)
            while bytes.count < 16_384, Date() < deadline {
                let count = recv(connection, &buffer, buffer.count, 0)
                if count <= 0 { break }
                bytes.append(contentsOf: buffer.prefix(count))
                if bytes.range(of: Data("\r\n\r\n".utf8)) != nil { break }
            }
            guard bytes.count < 16_384, let text = String(data: bytes, encoding: .utf8),
                  let line = text.components(separatedBy: "\r\n").first else { continue }
            let parts = line.split(separator: " ")
            guard parts.count == 3, parts[0] == "GET", parts[1].hasPrefix("/auth/callback?"),
                  let url = URL(string: "http://127.0.0.1:\(redirect.port!)" + parts[1]) else { continue }
            let body = "Sign-in response received. Return to Gym Assistant to check whether authorization succeeded."
            let response = "HTTP/1.1 200 OK\r\nContent-Type: text/plain; charset=utf-8\r\nCache-Control: no-store\r\nConnection: close\r\nContent-Length: \(body.utf8.count)\r\n\r\n" + body
            _ = response.withCString { send(connection, $0, response.utf8.count, 0) }
            return url
        }
        throw ChatGPTConnectionError.timeout
    }
}
