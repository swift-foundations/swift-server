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

/// The dependency key backing ``Dependency/Values/server``. Live and test both default to an empty
/// container — the same "no ambient request outside a request scope" contract the flat
/// ``Dependency/Values/request`` key carries, expressed through the container.
private enum ServerKey: Dependency.Key {}

extension ServerKey {
    static let liveValue = Server.Dependencies.Container()
    static let testValue = Server.Dependencies.Container()
}

extension Dependency.Values {
    /// The ambient ``Server/Dependencies/Container`` — the engine-free server membrane's values for
    /// the in-flight request.
    ///
    /// Read the request through it, which names which membrane you mean:
    ///
    /// ```swift
    /// @Dependency(\.server.request) var request
    /// ```
    ///
    /// Overrides compose through the container as you would expect — verified against a running
    /// binary, not merely compiled:
    ///
    /// ```swift
    /// withDependencies {
    ///     $0.server.request = request
    /// } operation: {
    ///     …  // @Dependency(\.server.request) observes `request` here
    /// }
    /// ```
    public var server: Server.Dependencies.Container {
        get { self[ServerKey.self] }
        set { self[ServerKey.self] = newValue }
    }
}
