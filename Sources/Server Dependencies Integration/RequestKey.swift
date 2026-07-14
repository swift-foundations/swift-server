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

public import Dependencies
public import Server
public import Server_Shared

extension Dependency.Values {
    /// The ambient ``Server/Request`` for the in-flight request, or `nil` outside a request scope.
    ///
    /// - Important: **Superseded spelling — migrating to ``Dependency/Values/server``.** Prefer
    ///   `@Dependency(\.server.request)`, which names *which* request it means. Two membranes vend an
    ///   ambient request — this one (the engine-free `Server.Request`) and
    ///   swift-server-foundation-vapor's (the engine type, `Vapor.Request`) — and both historically
    ///   spelled it `\.request`. This flat spelling is removed once every call site in the ecosystem
    ///   has moved.
    ///
    /// ## This is an ALIAS onto the container, not a second storage slot — and that is load-bearing
    ///
    /// It forwards to ``Server/Dependencies/Container/request``. There is exactly **one** storage
    /// slot, so the two spellings cannot diverge, and the migration is safe in any order:
    ///
    /// - a writer on either spelling is observed by a reader on either spelling;
    /// - a *nested* `withDependencies` override on either spelling shadows both, as it must;
    /// - any call site may migrate whenever it likes, with no coordination between repos.
    ///
    /// Had these stayed two independent keys, **every** writer in the ecosystem would have had to set
    /// both — including writers in repos this seat does not own. One that set only the flat key would
    /// leave the container holding a stale outer value, and every migrated read would be quietly
    /// wrong. That failure compiles. The alias makes it unrepresentable.
    public var request: Server.Request? {
        get { self.server.request }
        set { self.server.request = newValue }
    }
}
