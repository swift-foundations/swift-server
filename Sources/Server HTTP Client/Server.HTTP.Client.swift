// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-server open source project
//
// Copyright (c) 2026 Coen ten Thije Boonkkamp and the swift-server project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

public import Server_Shared

internal import AsyncHTTPClient
internal import NIOCore
internal import NIOHTTP1

extension Server.HTTP {
    /// A thin async HTTP client over async-http-client.
    ///
    /// Build one with ``init(timeout:)`` and issue requests with ``send(_:)`` (or the ``get(_:headers:)``
    /// / ``post(_:body:headers:)`` conveniences); call ``shutdown()`` when done. No async-http-client
    /// type crosses the surface.
    public struct Client: Sendable {
        let http: HTTPClient
        let timeout: Duration

        init(http: HTTPClient, timeout: Duration) {
            self.http = http
            self.timeout = timeout
        }
    }
}

extension Server.HTTP.Client {
    /// Creates a client owning its own event-loop group.
    public init(timeout: Duration = .seconds(30)) {
        self.init(http: HTTPClient(eventLoopGroupProvider: .singleton), timeout: timeout)
    }

    /// Issues a request and returns the collected response.
    public func send(
        _ request: Server.HTTP.Request
    ) async throws(Server.HTTP.Error) -> Server.HTTP.Response {
        var engineRequest = HTTPClientRequest(url: request.url)
        engineRequest.method = request.method.http
        for field in request.headers.fields {
            engineRequest.headers.add(name: field.name, value: field.value)
        }
        if !request.body.isEmpty {
            engineRequest.body = .bytes(request.body)
        }

        let engineResponse: HTTPClientResponse
        do {
            engineResponse = try await http.execute(engineRequest, deadline: Self.deadline(after: timeout))
        } catch {
            throw Server.HTTP.Error.transport("\(error)")
        }

        let buffer: ByteBuffer
        do {
            buffer = try await engineResponse.body.collect(upTo: 100 * 1024 * 1024)
        } catch {
            throw Server.HTTP.Error.transport("\(error)")
        }

        var headers = Server.Headers()
        for field in engineResponse.headers {
            headers.add(name: field.name, value: field.value)
        }

        return Server.HTTP.Response(
            status: Server.Status(
                code: Int(engineResponse.status.code),
                reason: engineResponse.status.reasonPhrase
            ),
            headers: headers,
            body: Array(buffer.readableBytesView)
        )
    }

    /// Issues a `GET` request.
    public func get(
        _ url: String,
        headers: Server.Headers = .init()
    ) async throws(Server.HTTP.Error) -> Server.HTTP.Response {
        try await send(Server.HTTP.Request(method: .get, url: url, headers: headers))
    }

    /// Issues a `POST` request with a byte body.
    public func post(
        _ url: String,
        body: [UInt8] = [],
        headers: Server.Headers = .init()
    ) async throws(Server.HTTP.Error) -> Server.HTTP.Response {
        try await send(Server.HTTP.Request(method: .post, url: url, headers: headers, body: body))
    }

    /// Shuts the client and its event-loop group down.
    public func shutdown() async throws(Server.HTTP.Error) {
        do {
            try await http.shutdown()
        } catch {
            throw Server.HTTP.Error.transport("\(error)")
        }
    }

    private static func deadline(after timeout: Duration) -> NIODeadline {
        let (seconds, attoseconds) = timeout.components
        let nanoseconds = seconds * 1_000_000_000 + attoseconds / 1_000_000_000
        return NIODeadline.now() + .nanoseconds(nanoseconds)
    }
}
