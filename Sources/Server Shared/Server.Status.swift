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

extension Server {
    /// An HTTP response status, carried by both `Server.Response` and thrown `Server.Error`
    /// values so that a handler can map an error domain onto a status uniformly.
    public struct Status: Sendable, Hashable {
        public let code: Int
        public let reason: String

        public init(code: Int, reason: String) {
            self.code = code
            self.reason = reason
        }
    }
}

extension Server.Status {
    /// A Boolean value indicating whether the status code is in the 2xx range.
    public var isSuccess: Bool { (200..<300).contains(code) }

    /// A Boolean value indicating whether the status code is in the 3xx range.
    public var isRedirect: Bool { (300..<400).contains(code) }
}

extension Server.Status {
    public static var ok: Self { .init(code: 200, reason: "OK") }
    public static var created: Self { .init(code: 201, reason: "Created") }
    public static var accepted: Self { .init(code: 202, reason: "Accepted") }
    public static var noContent: Self { .init(code: 204, reason: "No Content") }
    public static var found: Self { .init(code: 302, reason: "Found") }
    public static var seeOther: Self { .init(code: 303, reason: "See Other") }
    public static var notModified: Self { .init(code: 304, reason: "Not Modified") }
    public static var badRequest: Self { .init(code: 400, reason: "Bad Request") }
    public static var unauthorized: Self { .init(code: 401, reason: "Unauthorized") }
    public static var forbidden: Self { .init(code: 403, reason: "Forbidden") }
    public static var notFound: Self { .init(code: 404, reason: "Not Found") }
    public static var methodNotAllowed: Self { .init(code: 405, reason: "Method Not Allowed") }
    public static var conflict: Self { .init(code: 409, reason: "Conflict") }
    public static var unprocessableEntity: Self { .init(code: 422, reason: "Unprocessable Entity") }
    public static var tooManyRequests: Self { .init(code: 429, reason: "Too Many Requests") }
    public static var internalServerError: Self { .init(code: 500, reason: "Internal Server Error") }
    public static var badGateway: Self { .init(code: 502, reason: "Bad Gateway") }
    public static var serviceUnavailable: Self { .init(code: 503, reason: "Service Unavailable") }
}
