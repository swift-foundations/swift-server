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
public import SQL

internal import Logging
internal import PostgresNIO

extension Server.PostgreSQL {
    /// The PostgresNIO Live conformance of ``SQL/Database``.
    ///
    /// Build a pooled executor with ``init(configuration:)`` and service its pool by calling
    /// ``run()`` in a long-lived task (the pool only leases connections while `run()` is
    /// executing). The ``SQL/Database`` scopes — ``read(_:)``, ``write(_:)``,
    /// ``withRollback(_:)`` — each lease a pooled connection and hand the body a
    /// ``Server/PostgreSQL/Connection`` as an `any SQL.Connection`; no PostgresNIO type ever
    /// crosses the public surface.
    public struct Executor: Sendable {
        let client: PostgresClient
        let logger: Logger

        init(client: PostgresClient, logger: Logger) {
            self.client = client
            self.logger = logger
        }
    }
}

extension Server.PostgreSQL.Executor {
    /// Builds a pooled executor. Remember to call ``run()`` in a long-lived task before issuing
    /// queries — the pool only leases connections while `run()` is executing.
    public init(configuration: Server.PostgreSQL.Configuration) {
        var logger = Logger(label: "server.postgresql")
        logger.logLevel = .critical
        self.init(
            client: PostgresClient(configuration: configuration.postgres),
            logger: logger
        )
    }

    /// Services the connection pool. Call once in a long-lived task; returns when the pool shuts
    /// down.
    public func run() async {
        await client.run()
    }
}

extension Server.PostgreSQL.Executor: SQL.Database {
    /// Runs `body` against a leased pooled connection WITHOUT a transaction.
    ///
    /// PostgreSQL auto-commits every statement outside an explicit transaction block, so a read
    /// scope needs no `BEGIN`/`COMMIT`: the body observes a consistent single-statement view per
    /// query and the connection is returned to the pool when the scope ends. Use ``write(_:)`` when
    /// the body's statements must commit or roll back atomically.
    public func read<Value: Sendable>(
        _ body: @Sendable (any SQL.Connection) async throws(SQL.Error) -> Value
    ) async throws(SQL.Error) -> Value {
        let logger = logger
        do {
            return try await client.withConnection { connection in
                try await body(Server.PostgreSQL.Connection(connection: connection, logger: logger))
            }
        } catch let error as SQL.Error {
            throw error
        } catch {
            throw SQL.Error.connection("\(error)")
        }
    }

    /// Runs `body` inside a write transaction: `BEGIN`, the body against a leased connection, then
    /// `COMMIT` on success or `ROLLBACK` on a thrown error.
    public func write<Value: Sendable>(
        _ body: @Sendable (any SQL.Connection) async throws(SQL.Error) -> Value
    ) async throws(SQL.Error) -> Value {
        try await withinTransaction(finish: "COMMIT", onError: "ROLLBACK", body)
    }

    /// Runs `body` inside a transaction that always ends with `ROLLBACK` — the affordance for
    /// observing a statement's effect without persisting it.
    public func withRollback<Value: Sendable>(
        _ body: @Sendable (any SQL.Connection) async throws(SQL.Error) -> Value
    ) async throws(SQL.Error) -> Value {
        try await withinTransaction(finish: "ROLLBACK", onError: "ROLLBACK", body)
    }
}

extension Server.PostgreSQL.Executor {
    private func withinTransaction<Value: Sendable>(
        finish: String,
        onError: String,
        _ body: @Sendable (any SQL.Connection) async throws(SQL.Error) -> Value
    ) async throws(SQL.Error) -> Value {
        let logger = logger
        do {
            return try await client.withConnection { connection in
                let scoped = Server.PostgreSQL.Connection(connection: connection, logger: logger)
                _ = try await connection.query("BEGIN", logger: logger)
                do {
                    let value = try await body(scoped)
                    _ = try await connection.query(PostgresQuery(unsafeSQL: finish), logger: logger)
                    return value
                } catch {
                    _ = try? await connection.query(PostgresQuery(unsafeSQL: onError), logger: logger)
                    throw error
                }
            }
        } catch let error as SQL.Error {
            throw error
        } catch {
            throw SQL.Error.transaction("\(error)")
        }
    }
}
