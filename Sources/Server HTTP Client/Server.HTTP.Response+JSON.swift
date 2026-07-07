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

// Foundation exception: JSONDecoder is the v0 body deserializer. The public return is a stdlib
// `Decodable`; only the implementation touches Foundation.
private import Foundation
public import Server_Shared

extension Server.HTTP.Response {
    /// Decodes the response body as JSON into the given `Decodable` type.
    public func json<Value: Decodable>(as type: Value.Type = Value.self) throws(Server.HTTP.Error) -> Value {
        do {
            return try JSONDecoder().decode(Value.self, from: Data(body))
        } catch {
            throw Server.HTTP.Error.decoding("\(Value.self)")
        }
    }
}
