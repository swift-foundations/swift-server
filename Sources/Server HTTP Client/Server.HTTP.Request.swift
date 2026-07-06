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
    /// An outbound HTTP request: method, absolute URL, headers, and a byte body.
    public struct Request: Sendable {
        public var method: Server.Method
        public var url: String
        public var headers: Server.Headers
        public var body: [UInt8]

        public init(
            method: Server.Method = .get,
            url: String,
            headers: Server.Headers = .init(),
            body: [UInt8] = []
        ) {
            self.method = method
            self.url = url
            self.headers = headers
            self.body = body
        }
    }
}
