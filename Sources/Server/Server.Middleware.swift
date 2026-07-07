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
    /// A hook that intercepts a request on the way in and the response on the way out.
    ///
    /// Middleware is composed outermost-first: the application builds a `Server.Responder` chain
    /// where each middleware receives the request and a `next` responder representing the rest of
    /// the chain. Call `next` to continue, or short-circuit by returning a response directly.
    public protocol Middleware: Sendable {
        func intercept(
            _ request: Server.Request,
            next: Server.Responder
        ) async throws(Server.Error) -> Server.Response
    }
}

// Deliberately heterogeneous middleware stack: the array holds distinct
// concrete Middleware conformers; an existential element type is the design.
// swiftlint:disable:next no_any_protocol_existential
extension [any Server.Middleware] {
    /// Folds this middleware stack around a base responder, producing a single responder. The first
    /// element becomes the outermost layer (it runs first on the way in, last on the way out).
    public func chain(around base: @escaping Server.Responder) -> Server.Responder {
        var responder = base
        for layer in reversed() {
            let next = responder
            responder = { (request: Server.Request) async throws(Server.Error) -> Server.Response in
                try await layer.intercept(request, next: next)
            }
        }
        return responder
    }
}
