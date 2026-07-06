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

extension Server.Status {
    /// The engine status for this institute status.
    var vapor: HTTPResponseStatus {
        HTTPResponseStatus(statusCode: code, reasonPhrase: reason)
    }
}
