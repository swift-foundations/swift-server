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
    /// An ordered set of named migrations plus a runner, matching the first consumer's use of
    /// `Records.Database.Migrator`: register migrations in order, then `migrate(_:)` applies the
    /// pending ones inside transactions and records each in an applied-migrations table.
    public struct Migrator: Sendable {
        /// The registered migrations, in registration (application) order.
        public private(set) var migrations: [Server.PostgreSQL.Migration]

        public init() {
            self.migrations = []
        }
    }
}

extension Server.PostgreSQL.Migrator {
    /// The name of the table used to record applied migrations.
    public static var appliedTableName: String { "_server_migrations" }

    /// The registered migration names, in application order. Pure — testable without a database.
    public var names: [String] { migrations.map(\.name) }

    /// Registers a migration. Registration order is application order.
    public mutating func register(
        _ name: String,
        up: @escaping @Sendable (Server.PostgreSQL.Executor) async throws(Server.PostgreSQL.Error) -> Void
    ) {
        migrations.append(Server.PostgreSQL.Migration(name: name, up: up))
    }

    /// Appends an already-built migration.
    public mutating func register(_ migration: Server.PostgreSQL.Migration) {
        migrations.append(migration)
    }

    /// Computes which registered migrations are not yet in `applied`, preserving application order.
    /// Pure — testable without a database.
    public func pending(applied: Set<String>) -> [Server.PostgreSQL.Migration] {
        migrations.filter { !applied.contains($0.name) }
    }

    /// Applies every pending migration in order. Each runs inside its own transaction together with
    /// the insert of its bookkeeping row, so a failed migration leaves no partial record.
    public func migrate(_ executor: Server.PostgreSQL.Executor) async throws(Server.PostgreSQL.Error) {
        let created = Server.PostgreSQL.Query(
            sql: """
                CREATE TABLE IF NOT EXISTS \(Server.PostgreSQL.Migrator.appliedTableName) (
                    name TEXT PRIMARY KEY,
                    applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
                )
                """
        )
        _ = try await executor.execute(created)

        let appliedNames = try await executor.fetchAll(
            Server.PostgreSQL.Query(sql: "SELECT name FROM \(Server.PostgreSQL.Migrator.appliedTableName)")
        ) { (row: Server.PostgreSQL.Row) throws(Server.PostgreSQL.Error) -> String in
            try row.string("name")
        }

        let applied = Set(appliedNames)

        for migration in pending(applied: applied) {
            try await executor.transaction { (transaction: Server.PostgreSQL.Executor) async throws(Server.PostgreSQL.Error) -> Void in
                try await migration.up(transaction)
                _ = try await transaction.execute(
                    Server.PostgreSQL.Query(
                        sql: "INSERT INTO \(Server.PostgreSQL.Migrator.appliedTableName) (name) VALUES ($1)",
                        bindings: [.text(migration.name)]
                    )
                )
            }
        }
    }
}
