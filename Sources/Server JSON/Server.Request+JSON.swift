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

private import Byte_Primitive
public import JSON
public import Server

extension Server.Request {
    /// Decodes the request body as JSON into the given `JSON.Serializable` type.
    public func json<Value: JSON.Serializable>(
        as type: Value.Type = Value.self
    ) throws(Server.Error) -> Value {
        do {
            return try Value(jsonBytes: body.map(Byte.init))
        } catch {
            throw Server.Error.decoding("\(Value.self)")
        }
    }
}
