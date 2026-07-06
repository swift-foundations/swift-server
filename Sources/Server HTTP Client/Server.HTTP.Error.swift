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
    /// The typed error domain thrown by the outbound client.
    public enum Error: Swift.Error, Sendable {
        /// The request URL was not valid.
        case invalidURL(String)
        /// The request failed at the transport layer (connection, timeout, TLS, …).
        case transport(String)
        /// A request body could not be encoded.
        case encoding(String)
        /// A response body could not be decoded into the requested type.
        case decoding(String)
    }
}
