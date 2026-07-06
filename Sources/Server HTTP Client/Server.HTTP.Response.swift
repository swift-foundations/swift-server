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

extension Server.HTTP {
    /// An outbound HTTP response: status, headers, and a byte body.
    public struct Response: Sendable {
        public let status: HTTP.Status
        public let headers: HTTP.Headers
        public let body: [UInt8]

        public init(
            status: HTTP.Status,
            headers: HTTP.Headers = .init(),
            body: [UInt8] = []
        ) {
            self.status = status
            self.headers = headers
            self.body = body
        }
    }
}

extension Server.HTTP.Response {
    /// The body decoded as a UTF-8 string.
    public var bodyString: String {
        String(decoding: body, as: UTF8.self)
    }
}
