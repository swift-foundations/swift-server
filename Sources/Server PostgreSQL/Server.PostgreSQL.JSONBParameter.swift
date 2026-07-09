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

internal import NIOCore
internal import PostgresNIO
internal import Server_Shared

extension Server.PostgreSQL {
    /// A raw-bytes `jsonb` bind parameter.
    ///
    /// PostgresNIO offers no direct "bind these UTF-8 JSON bytes as `jsonb`" affordance without
    /// re-encoding through a `Codable` round-trip, so this tiny encoder emits the PostgreSQL binary
    /// `jsonb` wire format directly: a single version byte `0x01` followed by the JSON bytes. It
    /// backs ``SQL/Value/jsonb(_:)``.
    struct JSONBParameter: PostgresNonThrowingEncodable {
        let bytes: [UInt8]
    }
}

extension Server.PostgreSQL.JSONBParameter {
    static var psqlType: PostgresDataType { .jsonb }
    static var psqlFormat: PostgresFormat { .binary }

    func encode<JSONEncoder: PostgresJSONEncoder>(
        into byteBuffer: inout ByteBuffer,
        context: PostgresEncodingContext<JSONEncoder>
    ) {
        byteBuffer.writeInteger(UInt8(0x01))
        byteBuffer.writeBytes(bytes)
    }
}
