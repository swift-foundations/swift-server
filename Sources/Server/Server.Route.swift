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
    /// A lightweight, discrete route registration: a method + literal path bound to a responder.
    ///
    /// This is the model `Server.Application.register(_:)` adapts onto the engine's router for
    /// endpoints registered individually (webhooks, well-known documents, static handlers). The
    /// application's pointfree-style catch-all seam (`run(decode:respond:)`) covers the general
    /// case where URL parsing is owned by the consumer's router.
    public struct Route: Sendable {
        public let method: HTTP.Method
        /// Literal path segments, such as `[".well-known", "security.txt"]`.
        public let path: [String]
        public let respond: Server.Responder

        public init(
            method: HTTP.Method,
            path: [String],
            respond: @escaping Server.Responder
        ) {
            self.method = method
            self.path = path
            self.respond = respond
        }
    }
}
