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

internal import Foundation
internal import Logging
internal import PostgresNIO

extension Server.PostgreSQL {
    /// Runs statements over PostgresNIO behind the institute surface.
    ///
    /// Build a pooled executor with ``init(configuration:)`` and service its pool by calling
    /// ``run()`` in a long-lived task (as the first consumer's `Database.pool` requires). The query
    /// methods (``execute(_:)``, ``fetchAll(_:decode:)``, ``fetchOne(_:decode:)``) and the
    /// transaction scopes (``transaction(_:)``, ``withRollback(_:)``) accept any
    /// ``Server/PostgreSQL/Statement`` and never surface a PostgresNIO type.
    public struct Executor: Sendable {
        let backing: Server.PostgreSQL.Executor.Backing
        let logger: Logger

        init(backing: Server.PostgreSQL.Executor.Backing, logger: Logger) {
            self.backing = backing
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
            backing: .client(PostgresClient(configuration: configuration.postgres)),
            logger: logger
        )
    }

    /// Services the connection pool. Call once in a long-lived task; returns when the pool shuts
    /// down. No-op for a connection-scoped executor.
    public func run() async {
        if case .client(let client) = backing {
            await client.run()
        }
    }
}

extension Server.PostgreSQL.Executor {
    /// Executes a statement and returns the number of rows the server produced.
    public func execute(
        _ statement: some Server.PostgreSQL.Statement
    ) async throws(Server.PostgreSQL.Error) -> Int {
        let sequence = try await rows(for: statement)
        var count = 0
        do {
            for try await _ in sequence { count += 1 }
        } catch {
            throw Server.PostgreSQL.Error.execution("\(error)")
        }
        return count
    }

    /// Executes a statement and decodes every row via the given closure.
    public func fetchAll<Value: Sendable>(
        _ statement: some Server.PostgreSQL.Statement,
        decode: (Server.PostgreSQL.Row) throws(Server.PostgreSQL.Error) -> Value
    ) async throws(Server.PostgreSQL.Error) -> [Value] {
        let sequence = try await rows(for: statement)
        var results: [Value] = []
        do {
            for try await row in sequence {
                results.append(try decode(Server.PostgreSQL.Row(row.makeRandomAccess())))
            }
        } catch let error as Server.PostgreSQL.Error {
            throw error
        } catch {
            throw Server.PostgreSQL.Error.execution("\(error)")
        }
        return results
    }

    /// Executes a statement and decodes the first row, or returns `nil` when there is none.
    public func fetchOne<Value: Sendable>(
        _ statement: some Server.PostgreSQL.Statement,
        decode: (Server.PostgreSQL.Row) throws(Server.PostgreSQL.Error) -> Value
    ) async throws(Server.PostgreSQL.Error) -> Value? {
        let sequence = try await rows(for: statement)
        do {
            for try await row in sequence {
                return try decode(Server.PostgreSQL.Row(row.makeRandomAccess()))
            }
        } catch let error as Server.PostgreSQL.Error {
            throw error
        } catch {
            throw Server.PostgreSQL.Error.execution("\(error)")
        }
        return nil
    }
}

extension Server.PostgreSQL.Executor {
    /// Runs `body` inside a transaction: `BEGIN`, then the body against a connection-scoped
    /// executor, then `COMMIT` on success or `ROLLBACK` on a thrown error.
    public func transaction<Value: Sendable>(
        _ body: @Sendable (Server.PostgreSQL.Executor) async throws(Server.PostgreSQL.Error) -> Value
    ) async throws(Server.PostgreSQL.Error) -> Value {
        try await withinConnection(finish: "COMMIT", onError: "ROLLBACK", body)
    }

    /// Runs `body` inside a transaction that always ends with `ROLLBACK` — the test-support
    /// affordance mirroring the first consumer's `db.withRollback`, so an assertion can observe a
    /// statement's effect without persisting it.
    public func withRollback<Value: Sendable>(
        _ body: @Sendable (Server.PostgreSQL.Executor) async throws(Server.PostgreSQL.Error) -> Value
    ) async throws(Server.PostgreSQL.Error) -> Value {
        try await withinConnection(finish: "ROLLBACK", onError: "ROLLBACK", body)
    }
}

extension Server.PostgreSQL.Executor {
    private func rows(
        for statement: some Server.PostgreSQL.Statement
    ) async throws(Server.PostgreSQL.Error) -> PostgresRowSequence {
        let query = PostgresQuery(unsafeSQL: statement.sql, binds: Self.bindings(for: statement))
        do {
            switch backing {
            case .client(let client): return try await client.query(query, logger: logger)
            case .connection(let connection): return try await connection.query(query, logger: logger)
            }
        } catch {
            throw Server.PostgreSQL.Error.execution("\(error)")
        }
    }

    private func withinConnection<Value: Sendable>(
        finish: String,
        onError: String,
        _ body: @Sendable (Server.PostgreSQL.Executor) async throws(Server.PostgreSQL.Error) -> Value
    ) async throws(Server.PostgreSQL.Error) -> Value {
        guard case .client(let client) = backing else {
            throw Server.PostgreSQL.Error.transaction("a transaction requires a pooled executor")
        }
        let logger = logger
        do {
            return try await client.withConnection { connection in
                let scoped = Server.PostgreSQL.Executor(backing: .connection(connection), logger: logger)
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
        } catch let error as Server.PostgreSQL.Error {
            throw error
        } catch {
            throw Server.PostgreSQL.Error.transaction("\(error)")
        }
    }

    private static func bindings(for statement: some Server.PostgreSQL.Statement) -> PostgresBindings {
        var binds = PostgresBindings(capacity: statement.bindings.count)
        for value in statement.bindings {
            switch value {
            case .text(let text): binds.append(text)
            case .int(let int): binds.append(int)
            case .int64(let int): binds.append(int)
            case .double(let double): binds.append(double)
            case .bool(let bool): binds.append(bool)
            case .uuid(let uuid): binds.append(uuid)
            case .timestamp(let date): binds.append(date)
            case .null: binds.appendNull()
            }
        }
        return binds
    }
}
