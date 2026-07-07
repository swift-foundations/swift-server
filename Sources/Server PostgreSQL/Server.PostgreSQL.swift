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
    /// The PostgresNIO Live conformance of the L3 `SQL.Database` interface (institute
    /// server-stack architecture Q3, item 4).
    ///
    /// The engine-free execution vocabulary — the statement seam, the binding values, the decoded
    /// row, the connection / reader / database handles, and the migrator — lives in the L3
    /// `swift-sql` and `swift-migrations` packages. This namespace supplies the single live
    /// conformance that runs those interfaces over PostgresNIO behind the institute membrane:
    /// ``Server/PostgreSQL/Executor`` is a `SQL.Database`, and every PostgresNIO import is
    /// `internal` so no engine type crosses the public surface.
    public enum PostgreSQL {}
}
