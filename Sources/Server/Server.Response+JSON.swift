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

// Foundation exception: JSONEncoder is the v0 serializer for the `Encodable` convenience.
// The public parameter is a stdlib `Encodable`, not a Foundation type; only the internal
// implementation touches Foundation. An institute-native JSON serializer replaces this later.
private import Foundation

extension Server.Response {
    /// An `application/json` response encoding a value with `JSONEncoder`.
    public static func json(
        _ value: some Encodable,
        status: HTTP.Status = .ok
    ) throws(Server.Error) -> Self {
        let data: Data
        do {
            data = try JSONEncoder().encode(value)
        } catch {
            throw Server.Error.encoding("\(type(of: value))")
        }
        return Self(
            status: status,
            headers: HTTP.Headers(["Content-Type": "application/json; charset=utf-8"]),
            body: Array(data)
        )
    }
}
