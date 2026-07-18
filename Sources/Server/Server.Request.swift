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

public import HTTP_Standard

extension Server {
    /// A typed, engine-free snapshot of an inbound HTTP request handed to a `Server.Responder`.
    ///
    /// This is the value the consumer's route decoder inspects. Transport integrations construct
    /// it at their boundary.
    public struct Request: Sendable {
        public let method: HTTP.Method
        /// Path components with empty segments removed: `/analytics/user` → `["analytics", "user"]`.
        public let path: [String]
        /// The raw query string (everything after `?`), or `nil` when absent.
        public let query: String?
        public let headers: HTTP.Headers
        /// The collected request body, or an empty array when there was none.
        public let body: [UInt8]

        public init(
            method: HTTP.Method,
            path: [String],
            query: String? = nil,
            headers: HTTP.Headers = .init(),
            body: [UInt8] = []
        ) {
            self.method = method
            self.path = path
            self.query = query
            self.headers = headers
            self.body = body
        }
    }
}

extension Server.Request {
    /// The joined path, always leading-slashed: `["analytics", "user"]` → `/analytics/user`.
    public var pathString: String {
        "/" + path.joined(separator: "/")
    }

    /// The body decoded as a UTF-8 string.
    public var bodyString: String {
        String(decoding: body, as: UTF8.self)
    }
}
