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

internal import Server_Shared

internal import PostgresNIO

extension Server.PostgreSQL.Executor {
    /// The engine handle an executor runs against: either the pooled client (the common case) or a
    /// single connection bound to an in-flight transaction.
    enum Backing: Sendable {
        case client(PostgresClient)
        case connection(PostgresConnection)
    }
}
