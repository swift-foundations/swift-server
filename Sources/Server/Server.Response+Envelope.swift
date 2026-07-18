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

// Foundation exception: JSONEncoder is the v0 serializer for the envelope, and ISO8601DateFormatter
// stamps the `timestamp`. The public parameters are stdlib `Encodable`/`String`/`Bool`, not
// Foundation types; only the internal implementation touches Foundation, exactly as the sibling
// `Server.Response+JSON.swift` does. An institute-native JSON serializer replaces this later.
private import Foundation
public import HTTP_Standard

extension Server.Response {
    /// An `application/json` response wrapping `value` in the standard envelope
    /// `{ success, data, message, timestamp }`.
    ///
    /// This is the payload-carrying overload; the no-data ``json(success:message:status:)`` sibling
    /// omits `data`. `status` sets the HTTP response status (it is not a body field). Encoder
    /// handling mirrors ``json(_:status:)``: a `JSONEncoder` failure throws ``Server/Error/encoding``.
    public static func json(
        success: Bool,
        data: some Encodable,
        message: String? = nil,
        status: HTTP.Status = .ok
    ) throws(Server.Error) -> Self {
        try encodedEnvelope(
            Envelope(success: success, data: data, message: message, timestamp: Self.timestamp()),
            status: status
        )
    }

    /// An `application/json` response wrapping the standard envelope `{ success, message, timestamp }`
    /// with no `data` payload. `status` sets the HTTP response status (it is not a body field).
    public static func json(
        success: Bool,
        message: String? = nil,
        status: HTTP.Status = .ok
    ) throws(Server.Error) -> Self {
        // The `String` type argument is inert: `data` is `nil`, so the payload key serializes as
        // `null` regardless of the phantom `Data` type.
        try encodedEnvelope(
            Envelope<String>(success: success, data: nil, message: message, timestamp: Self.timestamp()),
            status: status
        )
    }

    private static func encodedEnvelope(
        _ envelope: some Encodable,
        status: HTTP.Status
    ) throws(Server.Error) -> Self {
        let data: Data
        do {
            data = try JSONEncoder().encode(envelope)
        } catch {
            throw Server.Error.encoding("\(type(of: envelope))")
        }
        return Self(
            status: status,
            headers: HTTP.Headers(["Content-Type": "application/json; charset=utf-8"]),
            body: Array(data)
        )
    }

    private static func timestamp() -> String {
        ISO8601DateFormatter().string(from: Date())
    }
}
