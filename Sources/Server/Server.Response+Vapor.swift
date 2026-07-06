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

extension Server.Response {
    /// Bridges the institute response into an engine response at the membrane boundary.
    func vapor() -> Vapor.Response {
        var buffer = ByteBufferAllocator().buffer(capacity: body.count)
        buffer.writeBytes(body)
        return Vapor.Response(
            status: status.vapor,
            headers: headers.vapor,
            body: .init(buffer: buffer)
        )
    }
}
