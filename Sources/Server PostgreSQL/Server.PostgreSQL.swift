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

extension Server {
    /// The persistence-execution membrane: runs SQL statements over PostgresNIO behind an
    /// institute surface, with a DSL-free ``Server/PostgreSQL/Statement`` seam so the module stays
    /// resolvable even while the Structured Queries DSL package is unresolvable in the ecosystem
    /// graph (see `Research/consumer-call-site-inventory.md`).
    public enum PostgreSQL {}
}
