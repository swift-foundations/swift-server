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

extension Server.Request {
    /// Bridges an engine request into the institute request context at the membrane boundary.
    init(_ vapor: Vapor.Request) {
        let path = vapor.url.path.split(separator: "/").map(String.init)
        var body: [UInt8] = []
        if let buffer = vapor.body.data {
            body = Array(buffer.readableBytesView)
        }
        self.init(
            method: HTTP.Method(vapor.method),
            path: path,
            query: vapor.url.query,
            headers: HTTP.Headers(vapor.headers),
            body: body
        )
    }
}
