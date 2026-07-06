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

internal import Server_Shared
internal import Vapor

private typealias Server = Server_Shared.Server

extension Server.Headers {
    /// The engine headers for these institute headers.
    var vapor: HTTPHeaders {
        var headers = HTTPHeaders()
        for field in fields {
            headers.add(name: field.name, value: field.value)
        }
        return headers
    }

    /// Maps engine headers onto institute headers, preserving order and duplicates.
    init(_ vapor: HTTPHeaders) {
        self.init(vapor.map { Server.Headers.Field(name: $0.name, value: $0.value) })
    }
}
