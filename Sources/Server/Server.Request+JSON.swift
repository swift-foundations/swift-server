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

// Foundation exception: JSONDecoder is the v0 deserializer for the request-body convenience.
// The public parameter/return is a stdlib `Decodable`, not a Foundation type; only the
// internal implementation touches Foundation.
private import Foundation
public import Server_Shared

extension Server.Request {
    /// Decodes the request body as JSON into the given `Decodable` type.
    public func json<Value: Decodable>(as type: Value.Type = Value.self) throws(Server.Error) -> Value {
        do {
            return try JSONDecoder().decode(Value.self, from: Data(body))
        } catch {
            throw Server.Error.decoding("\(Value.self)")
        }
    }
}
