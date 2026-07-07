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
internal import RFC_4122
internal import SQL
internal import Time_Primitive

internal import Foundation
internal import Logging
internal import NIOCore
internal import PostgresNIO

extension Server.PostgreSQL {
    /// A connection-scoped ``SQL/Connection`` bound to a single leased PostgresNIO connection.
    ///
    /// This is the type an ``Server/PostgreSQL/Executor`` read/write/rollback scope hands to its
    /// body as an `any SQL.Connection`. It runs any ``SQL/Statement`` (translating the engine-free
    /// ``SQL/Value`` bindings into `PostgresBindings`) and decodes rows through
    /// ``Server/PostgreSQL/Row`` — no PostgresNIO type ever surfaces.
    struct Connection: Sendable {
        let connection: PostgresConnection
        let logger: Logger

        init(connection: PostgresConnection, logger: Logger) {
            self.connection = connection
            self.logger = logger
        }
    }
}

extension Server.PostgreSQL.Connection: SQL.Connection {
    func execute(_ statement: some SQL.Statement) async throws(SQL.Error) -> Int {
        let sequence = try await rows(for: statement)
        var count = 0
        do {
            for try await _ in sequence { count += 1 }
        } catch {
            throw SQL.Error.execution("\(error)")
        }
        return count
    }

    func fetchAll<Value: Sendable>(
        _ statement: some SQL.Statement,
        decode: (any SQL.Row) throws(SQL.Error) -> Value
    ) async throws(SQL.Error) -> [Value] {
        let sequence = try await rows(for: statement)
        var results: [Value] = []
        do {
            for try await row in sequence {
                results.append(try decode(Server.PostgreSQL.Row(row.makeRandomAccess())))
            }
        } catch let error as SQL.Error {
            throw error
        } catch {
            throw SQL.Error.execution("\(error)")
        }
        return results
    }

    func fetchOne<Value: Sendable>(
        _ statement: some SQL.Statement,
        decode: (any SQL.Row) throws(SQL.Error) -> Value
    ) async throws(SQL.Error) -> Value? {
        let sequence = try await rows(for: statement)
        do {
            for try await row in sequence {
                return try decode(Server.PostgreSQL.Row(row.makeRandomAccess()))
            }
        } catch let error as SQL.Error {
            throw error
        } catch {
            throw SQL.Error.execution("\(error)")
        }
        return nil
    }
}

extension Server.PostgreSQL.Connection {
    private func rows(
        for statement: some SQL.Statement
    ) async throws(SQL.Error) -> PostgresRowSequence {
        let query = PostgresQuery(unsafeSQL: statement.sql, binds: Self.bindings(for: statement))
        do {
            return try await connection.query(query, logger: logger)
        } catch {
            throw SQL.Error.execution("\(error)")
        }
    }

    /// Translates the engine-free ``SQL/Value`` bindings into `PostgresBindings`.
    ///
    /// `.uuid` and `.timestamp` round-trip through Foundation (`UUID`/`Date`) because those are the
    /// PostgresNIO bind types for `uuid`/`timestamptz` columns; the Foundation use is internal and
    /// never escapes the membrane. `.jsonb` binds via ``Server/PostgreSQL/JSONBParameter`` (the
    /// PostgreSQL binary `jsonb` wire format: a `0x01` version byte followed by the JSON bytes).
    static func bindings(for statement: some SQL.Statement) -> PostgresBindings {
        var binds = PostgresBindings(capacity: statement.bindings.count)
        for value in statement.bindings {
            switch value {
            case .text(let text): binds.append(text)
            case .int(let int): binds.append(int)
            case .int64(let int): binds.append(int)
            case .double(let double): binds.append(double)
            case .bool(let bool): binds.append(bool)
            case .uuid(let uuid): binds.append(Foundation.UUID(uuid: uuid.bytes))
            case .timestamp(let instant):
                let interval = Double(instant.secondsSinceUnixEpoch)
                    + Double(instant.nanosecondFraction) / 1_000_000_000
                binds.append(Date(timeIntervalSince1970: interval))
            case .blob(let bytes): binds.append(ByteBuffer(bytes: bytes))
            case .jsonb(let bytes): binds.append(Server.PostgreSQL.JSONBParameter(bytes: bytes))
            case .null: binds.appendNull()
            }
        }
        return binds
    }
}
