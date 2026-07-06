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
    /// The seam the executor runs: a prepared SQL string plus its positional bindings.
    ///
    /// This is the deliberate quarantine point for the Structured Queries DSL coupling. The DSL's
    /// `Statement.query.prepare { "$\($0)" }` produces exactly a `(sql, bindings)` pair; a bridge
    /// conforming a DSL statement to this protocol is a thin, removable adapter. Because the seam
    /// itself depends on nothing but the standard library, the executor and migrator build with or
    /// without the DSL package present.
    public protocol Statement: Sendable {
        /// The SQL text with `$1`, `$2`, … positional placeholders.
        var sql: String { get }
        /// The positional bindings, in `$1…$n` order.
        var bindings: [Server.PostgreSQL.Value] { get }
    }
}
