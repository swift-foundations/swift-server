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

extension Server.Method {
    /// The engine method for this institute method.
    var vapor: HTTPMethod {
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

    /// Maps an engine method back onto the institute method, defaulting to `.get` for methods the
    /// membrane does not model.
    init(_ vapor: HTTPMethod) {
        switch vapor {
        case .GET: self = .get
        case .POST: self = .post
        case .PUT: self = .put
        case .PATCH: self = .patch
        case .DELETE: self = .delete
        case .HEAD: self = .head
        case .OPTIONS: self = .options
        default: self = .get
        }
    }
}
