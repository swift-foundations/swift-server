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

// Foundation exception: JSONEncoder is the v0 body serializer. The public parameter is a stdlib
// `Encodable`; only the implementation touches Foundation.
private import Foundation
public import Server_Shared

extension Server.HTTP.Request {
    /// Builds a request whose body is a JSON encoding of `value`, with the JSON content type set.
    public static func json(
        _ method: HTTP.Method,
        url: String,
        headers: HTTP.Headers = .init(),
        value: some Encodable
    ) throws(Server.HTTP.Error) -> Self {
        let data: Data
        do {
            data = try JSONEncoder().encode(value)
        } catch {
            throw Server.HTTP.Error.encoding("\(type(of: value))")
        }
        var headers = headers
        headers.replace(name: "Content-Type", value: "application/json; charset=utf-8")
        return Self(method: method, url: url, headers: headers, body: Array(data))
    }
}
