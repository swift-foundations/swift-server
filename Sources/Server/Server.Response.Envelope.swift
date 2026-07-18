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

public import HTTP_Standard

extension Server.Response {
    /// The standard API response envelope serialized by ``json(success:data:message:status:)`` and
    /// its no-data sibling: `{ success, data, message, timestamp }`.
    ///
    /// `Data` is the payload's `Encodable` type; `data` and `message` are optional (encoded as
    /// `null` when absent), and `timestamp` is an ISO-8601 instant stamped at construction. It is a
    /// module-internal serialization detail — consumers build one indirectly through the
    /// `Server.Response.json` factories and decode the produced JSON on the wire.
    struct Envelope<Data: Encodable>: Encodable {
        let success: Bool
        let data: Data?
        let message: String?
        let timestamp: String
    }
}
