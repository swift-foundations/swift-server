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
    /// A concrete ad-hoc statement: raw SQL with positional bindings. The value-form conformer of
    /// ``Server/PostgreSQL/Statement`` for callers not going through the DSL bridge.
    public struct Query: Server.PostgreSQL.Statement {
        public let sql: String
        public let bindings: [Server.PostgreSQL.Value]

        public init(sql: String, bindings: [Server.PostgreSQL.Value] = []) {
            self.sql = sql
            self.bindings = bindings
        }
    }
}
