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

extension Server.PostgreSQL {
    /// A single named migration: an identifier plus the work that applies it.
    ///
    /// The `up` closure receives a transaction-scoped executor — every statement it runs commits
    /// atomically with the migration's bookkeeping row, mirroring the first consumer's
    /// `registerMigration("name") { db in … }` shape.
    public struct Migration: Sendable {
        public let name: String
        public let up: @Sendable (Server.PostgreSQL.Executor) async throws(Server.PostgreSQL.Error) -> Void

        public init(
            name: String,
            up: @escaping @Sendable (Server.PostgreSQL.Executor) async throws(Server.PostgreSQL.Error) -> Void
        ) {
            self.name = name
            self.up = up
        }
    }
}
