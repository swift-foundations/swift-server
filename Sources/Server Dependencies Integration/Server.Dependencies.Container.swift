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

public import Server
public import Server_Shared

extension Server.Dependencies {
    /// The ambient server-membrane values for the in-flight request, reached through
    /// ``Dependency/Values/server``.
    ///
    /// ## Why a container, and not a flat key
    ///
    /// Two membranes vend an ambient request: this one (`Server.Request` — engine-free) and
    /// `swift-server-foundation-vapor` (`Vapor.Request` — the engine type). Both previously spelled
    /// it `\.request`. That is not a naming quibble: a module importing both integrations would face
    /// two distinct `Dependency.Values.request` properties of *different types*, and the ambiguity
    /// is only latent today because no single module imports both.
    ///
    /// Naming the container makes the choice explicit and un-collidable at the call site —
    /// `@Dependency(\.server.request)` says *which* request it means:
    ///
    /// ```swift
    /// @Dependency(\.server.request) var request     // the membrane type
    /// @Dependency(\.vapor.request) var vaporRequest // the engine type
    /// ```
    ///
    /// The flat ``Dependency/Values/request`` still exists and still works; it is retired only once
    /// every call site in the ecosystem has moved, so no consumer breaks on the mint.
    public struct Container: Sendable {
        /// The ambient ``Server/Request``, or `nil` outside a request scope.
        ///
        /// `nil` is the honest default in both live and test: there is no ambient request before
        /// ``Server/Dependencies/Middleware`` has injected one, and a fabricated stand-in would let
        /// a graph read a request that never arrived.
        public var request: Server.Request?

        public init(request: Server.Request? = nil) {
            self.request = request
        }
    }
}
