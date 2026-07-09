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

/// The dependency key backing ``Dependency/Values/request``. Both the live and test values are
/// `nil`: there is no ambient request outside a request scope, so a graph that reads `\.request`
/// before ``Server/Dependencies/Middleware`` has injected one sees `nil` (and must handle it)
/// rather than a stale or fabricated request.
private enum RequestKey: Dependency.Key {}

extension RequestKey {
    static let liveValue: Server.Request? = nil
    static let testValue: Server.Request? = nil
}

extension Dependency.Values {
    /// The ambient ``Server/Request`` for the in-flight request, or `nil` outside a request scope.
    ///
    /// This is the engine-free membrane type — never `Vapor.Request`. Install
    /// ``Server/Dependencies/Middleware`` so each inbound request runs its responder inside a
    /// `withDependencies { $0.request = … }` scope; consumers then read it with
    /// `@Dependency(\.request) var request`.
    public var request: Server.Request? {
        get { self[RequestKey.self] }
        set { self[RequestKey.self] = newValue }
    }
}
