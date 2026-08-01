//
//  Server.Request.Scope.swift
//  swift-server
//
//  The engine-free request scope: the membrane twin of the engine-side
//  `\.vapor` scope (swift-server-vapor, Vapor.Request.Scope). Engine
//  adapters populate it at their request seams with the request HEAD —
//  method, path, query, headers — and an empty body. Body streaming and
//  collection remain an engine ("raw target") concern: call sites that
//  consume the body keep using the engine scope, so populating this scope
//  never forces eager body collection.
//

public import Dependencies
public import Server

extension Server.Request {
    public struct Scope: Sendable {
        public var request: Server.Request?

        public init(request: Server.Request? = nil) {
            self.request = request
        }
    }
}

extension Dependency.Values {
    /// `@Dependency(\.server.request)` — the current request as the
    /// engine-free membrane type, or `nil` outside a request context.
    public var server: Server.Request.Scope {
        get { self[ServerKey.self] }
        set { self[ServerKey.self] = newValue }
    }
}
