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

// Foundation exception: `UUID` and `Date` accessors return Foundation types — the natural output
// for `uuid` and `timestamptz` columns and what the first consumer's records decode to.
public import Foundation
internal import PostgresNIO

extension Server.PostgreSQL {
    /// A decoded result row, addressed by column name or index.
    ///
    /// The engine row is held privately; the public accessors return concrete Swift/Foundation
    /// types (never a PostgresNIO type), so no engine type crosses the membrane. Provided to a
    /// `fetchAll` / `fetchOne` decode closure, where it is consumed synchronously.
    public struct Row {
        private let row: PostgresRandomAccessRow

        init(_ row: PostgresRandomAccessRow) {
            self.row = row
        }
    }
}

extension Server.PostgreSQL.Row {
    private func decode<T: PostgresDecodable>(
        _ type: T.Type,
        column: String
    ) throws(Server.PostgreSQL.Error) -> T {
        do {
            return try row[column].decode(T.self)
        } catch {
            throw Server.PostgreSQL.Error.decoding("column \"\(column)\": \(error)")
        }
    }

    private func decode<T: PostgresDecodable>(
        _ type: T.Type,
        at index: Int
    ) throws(Server.PostgreSQL.Error) -> T {
        do {
            return try row[index].decode(T.self)
        } catch {
            throw Server.PostgreSQL.Error.decoding("column \(index): \(error)")
        }
    }

    // MARK: By column name

    public func string(_ column: String) throws(Server.PostgreSQL.Error) -> String { try decode(String.self, column: column) }
    public func int(_ column: String) throws(Server.PostgreSQL.Error) -> Int { try decode(Int.self, column: column) }
    public func int64(_ column: String) throws(Server.PostgreSQL.Error) -> Int64 { try decode(Int64.self, column: column) }
    public func double(_ column: String) throws(Server.PostgreSQL.Error) -> Double { try decode(Double.self, column: column) }
    public func bool(_ column: String) throws(Server.PostgreSQL.Error) -> Bool { try decode(Bool.self, column: column) }
    public func uuid(_ column: String) throws(Server.PostgreSQL.Error) -> UUID { try decode(UUID.self, column: column) }
    public func date(_ column: String) throws(Server.PostgreSQL.Error) -> Date { try decode(Date.self, column: column) }

    public func stringIfPresent(_ column: String) throws(Server.PostgreSQL.Error) -> String? { try decode(String?.self, column: column) }
    public func intIfPresent(_ column: String) throws(Server.PostgreSQL.Error) -> Int? { try decode(Int?.self, column: column) }
    public func uuidIfPresent(_ column: String) throws(Server.PostgreSQL.Error) -> UUID? { try decode(UUID?.self, column: column) }
    public func dateIfPresent(_ column: String) throws(Server.PostgreSQL.Error) -> Date? { try decode(Date?.self, column: column) }

    // MARK: By column index

    public func string(at index: Int) throws(Server.PostgreSQL.Error) -> String { try decode(String.self, at: index) }
    public func int(at index: Int) throws(Server.PostgreSQL.Error) -> Int { try decode(Int.self, at: index) }
    public func int64(at index: Int) throws(Server.PostgreSQL.Error) -> Int64 { try decode(Int64.self, at: index) }
    public func double(at index: Int) throws(Server.PostgreSQL.Error) -> Double { try decode(Double.self, at: index) }
    public func bool(at index: Int) throws(Server.PostgreSQL.Error) -> Bool { try decode(Bool.self, at: index) }
    public func uuid(at index: Int) throws(Server.PostgreSQL.Error) -> UUID { try decode(UUID.self, at: index) }
    public func date(at index: Int) throws(Server.PostgreSQL.Error) -> Date { try decode(Date.self, at: index) }
}
