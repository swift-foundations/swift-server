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

public import Server_Shared

extension Server {
    /// The core request→response seam: an async function that turns a typed request context into
    /// a response, throwing the typed `Server.Error` domain. Middleware wraps responders; the
    /// application's catch-all handler is itself a responder built from the consumer's
    /// route-decode and respond closures.
    public typealias Responder = @Sendable (Server.Request) async throws(Server.Error) -> Server.Response
}
