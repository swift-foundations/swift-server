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

extension Server {
    /// A typed, engine-free HTTP response returned by a `Server.Responder`.
    ///
    /// Build one with the convenience factories (``html(_:status:)``, ``json(_:status:)``,
    /// ``text(_:status:)``, ``redirect(to:permanent:)``, ``status(_:)``) rather than the memberwise
    /// initializer where possible; the internal `vapor()` bridge converts it at the boundary.
    public struct Response: Sendable {
        public var status: HTTP.Status
        public var headers: HTTP.Headers
        public var body: [UInt8]

        public init(
            status: HTTP.Status = .ok,
            headers: HTTP.Headers = .init(),
            body: [UInt8] = []
        ) {
            self.status = status
            self.headers = headers
            self.body = body
        }
    }
}

extension Server.Response {
    /// An `text/html` response from a rendered document string.
    public static func html(_ document: String, status: HTTP.Status = .ok) -> Self {
        Self(
            status: status,
            headers: HTTP.Headers(["Content-Type": "text/html; charset=utf-8"]),
            body: Array(document.utf8)
        )
    }

    /// An `application/json` response from an already-serialized JSON string.
    ///
    /// For encoding a value, see the `json(_:status:)` overload taking an `Encodable` in
    /// `Server.Response+JSON.swift`.
    public static func json(_ serialized: String, status: HTTP.Status = .ok) -> Self {
        Self(
            status: status,
            headers: HTTP.Headers(["Content-Type": "application/json; charset=utf-8"]),
            body: Array(serialized.utf8)
        )
    }

    /// A `text/plain` response.
    public static func text(_ string: String, status: HTTP.Status = .ok) -> Self {
        Self(
            status: status,
            headers: HTTP.Headers(["Content-Type": "text/plain; charset=utf-8"]),
            body: Array(string.utf8)
        )
    }

    /// A redirect response. `permanent` chooses 301 vs 303 (See Other, the safe default for
    /// POST-redirect-GET).
    public static func redirect(to location: String, permanent: Bool = false) -> Self {
        Self(
            status: permanent ? .movedPermanently : .seeOther,
            headers: HTTP.Headers(["Location": location])
        )
    }

    /// A bare status response with no body (e.g. `.noContent`).
    public static func status(_ status: HTTP.Status) -> Self {
        Self(status: status)
    }

    /// A raw-bytes response with an explicit content type.
    public static func bytes(_ body: [UInt8], contentType: String, status: HTTP.Status = .ok) -> Self {
        Self(
            status: status,
            headers: HTTP.Headers(["Content-Type": contentType]),
            body: body
        )
    }
}
