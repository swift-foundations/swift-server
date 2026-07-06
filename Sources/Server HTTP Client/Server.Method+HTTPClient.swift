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

internal import NIOHTTP1
internal import Server_Shared

extension Server.Method {
    /// The engine method for this institute method.
    var http: HTTPMethod {
        switch self {
        case .get: .GET
        case .post: .POST
        case .put: .PUT
        case .patch: .PATCH
        case .delete: .DELETE
        case .head: .HEAD
        case .options: .OPTIONS
        }
    }
}
