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

extension Server.PostgreSQL.Configuration {
    /// The transport security mode for the connection.
    public enum Security: Sendable, Hashable {
        /// Never use TLS.
        case disabled
        /// Use TLS if the server offers it, otherwise fall back to plaintext.
        case preferred
        /// Require TLS; fail the connection if unavailable.
        case required
    }
}
