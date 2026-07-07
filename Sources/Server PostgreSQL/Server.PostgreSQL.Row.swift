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
public import RFC_4122
public import SQL
public import Time_Primitive

internal import Foundation
internal import NIOCore
internal import PostgresNIO

extension Server.PostgreSQL {
    /// The PostgresNIO Live conformance of ``SQL/Row``.
    ///
    /// The engine row is held privately; accessors decode on demand and return institute vocabulary
    /// (``RFC_4122/UUID``, `Instant`) or stdlib types — never a PostgresNIO type. `uuid` decodes a
    /// Foundation `UUID` and converts via its 16-byte tuple; `timestamp` decodes a Foundation `Date`
    /// and converts to `Instant`; `bytes` decodes a `ByteBuffer` (covering `bytea`/`jsonb` columns).
    /// Provided to a `fetchAll` / `fetchOne` decode closure, where it is consumed synchronously.
    public struct Row: SQL.Row {
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
    ) throws(SQL.Error) -> T {
        do {
            return try row[column].decode(T.self)
        } catch {
            throw SQL.Error.decoding("column \"\(column)\": \(error)")
        }
    }

    private func decode<T: PostgresDecodable>(
        _ type: T.Type,
        at index: Int
    ) throws(SQL.Error) -> T {
        do {
            return try row[index].decode(T.self)
        } catch {
            throw SQL.Error.decoding("column \(index): \(error)")
        }
    }

    /// Converts a Foundation `UUID` to an ``RFC_4122/UUID`` via the shared 16-byte big-endian tuple.
    private static func convert(_ uuid: Foundation.UUID) -> RFC_4122.UUID {
        RFC_4122.UUID(bytes: uuid.uuid)
    }

    /// Converts a Foundation `Date` to an `Instant` via its Unix interval.
    private static func convert(_ date: Foundation.Date) -> Instant {
        instant(fromUnixInterval: date.timeIntervalSince1970)
    }

    /// Builds an `Instant` from a floating-point seconds-since-1970 interval.
    ///
    /// The seconds are floored so a pre-1970 (negative) interval still yields a non-negative
    /// `nanosecondFraction` in `Instant`'s required `0...999_999_999` range — e.g. `-0.5` becomes
    /// `(seconds: -1, nanos: 500_000_000)`. Sub-second precision beyond nanoseconds is rounded to
    /// the nearest nanosecond, carrying into the seconds if that rounds up to a full second.
    ///
    /// Exposed at `package` access as the engine-free seam the tests exercise for the interval edge
    /// cases (Foundation-free in its signature — the `Double` comes from `Date.timeIntervalSince1970`).
    package static func instant(fromUnixInterval interval: Double) -> Instant {
        let flooredSeconds = interval.rounded(.down)
        var seconds = Int64(flooredSeconds)
        var nanos = Int64(((interval - flooredSeconds) * 1_000_000_000).rounded())
        if nanos >= 1_000_000_000 {
            nanos -= 1_000_000_000
            seconds += 1
        }
        if nanos < 0 { nanos = 0 }
        return Instant(
            _unchecked: (),
            secondsSinceUnixEpoch: seconds,
            nanosecondFraction: Int32(nanos)
        )
    }

    // MARK: By column name

    public func string(_ column: String) throws(SQL.Error) -> String { try decode(String.self, column: column) }
    public func int(_ column: String) throws(SQL.Error) -> Int { try decode(Int.self, column: column) }
    public func int64(_ column: String) throws(SQL.Error) -> Int64 { try decode(Int64.self, column: column) }
    public func double(_ column: String) throws(SQL.Error) -> Double { try decode(Double.self, column: column) }
    public func bool(_ column: String) throws(SQL.Error) -> Bool { try decode(Bool.self, column: column) }
    public func uuid(_ column: String) throws(SQL.Error) -> RFC_4122.UUID { Self.convert(try decode(UUID.self, column: column)) }
    public func timestamp(_ column: String) throws(SQL.Error) -> Instant { Self.convert(try decode(Date.self, column: column)) }
    public func bytes(_ column: String) throws(SQL.Error) -> [UInt8] { Array(buffer: try decode(ByteBuffer.self, column: column)) }

    public func stringIfPresent(_ column: String) throws(SQL.Error) -> String? { try decode(String?.self, column: column) }
    public func intIfPresent(_ column: String) throws(SQL.Error) -> Int? { try decode(Int?.self, column: column) }
    public func uuidIfPresent(_ column: String) throws(SQL.Error) -> RFC_4122.UUID? { try decode(UUID?.self, column: column).map(Self.convert) }
    public func timestampIfPresent(_ column: String) throws(SQL.Error) -> Instant? { try decode(Date?.self, column: column).map(Self.convert) }

    // MARK: By column index

    public func string(at index: Int) throws(SQL.Error) -> String { try decode(String.self, at: index) }
    public func int(at index: Int) throws(SQL.Error) -> Int { try decode(Int.self, at: index) }
    public func int64(at index: Int) throws(SQL.Error) -> Int64 { try decode(Int64.self, at: index) }
    public func double(at index: Int) throws(SQL.Error) -> Double { try decode(Double.self, at: index) }
    public func bool(at index: Int) throws(SQL.Error) -> Bool { try decode(Bool.self, at: index) }
    public func uuid(at index: Int) throws(SQL.Error) -> RFC_4122.UUID { Self.convert(try decode(UUID.self, at: index)) }
    public func timestamp(at index: Int) throws(SQL.Error) -> Instant { Self.convert(try decode(Date.self, at: index)) }
    public func bytes(at index: Int) throws(SQL.Error) -> [UInt8] { Array(buffer: try decode(ByteBuffer.self, at: index)) }
}
