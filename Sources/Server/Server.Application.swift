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

// `package import`: the underlying Vapor.Application is exposed at PACKAGE scope only, so the
// sibling "Server Jobs" target can install a job registry onto the running app's queues. It never
// crosses the package boundary — the public surface stays engine-free.
package import Vapor

// Vapor also declares a `public protocol Server`, which collides with our `Server_Shared.Server`
// namespace inside this file. Public/package signatures below therefore spell the namespace out as
// `Server_Shared.Server`; the file-private alias disambiguates the (non-API) implementation bodies.
private typealias Server = Server_Shared.Server

extension Server_Shared.Server {
    /// The application: the membrane's bootstrap, lifecycle, and routing owner.
    ///
    /// Create one with ``make(configuration:)``, register discrete routes with ``register(_:)``
    /// and/or serve a pointfree-style router with ``run(middleware:configure:decode:respond:)``,
    /// and tear it down with ``shutdown()``. The underlying engine (`Vapor.Application`) is held at
    /// `package` scope for sibling membrane targets and never surfaces publicly.
    public final class Application {
        package let vapor: Vapor.Application
        public let configuration: Server_Shared.Server.Configuration

        package init(vapor: Vapor.Application, configuration: Server_Shared.Server.Configuration) {
            self.vapor = vapor
            self.configuration = configuration
        }
    }
}

extension Server_Shared.Server.Application {
    /// Boots an application from configuration. Convenience spelling of ``make(configuration:)``.
    public convenience init(
        configuration: Server_Shared.Server.Configuration = .init()
    ) async throws(Server_Shared.Server.Error) {
        let application = try await Server.Application.make(configuration: configuration)
        self.init(vapor: application.vapor, configuration: application.configuration)
    }

    /// Boots an application: constructs the engine, applies host/port/body-size configuration, and
    /// returns a ready-but-not-yet-serving application.
    public static func make(
        configuration: Server_Shared.Server.Configuration = .init()
    ) async throws(Server_Shared.Server.Error) -> Server_Shared.Server.Application {
        let environment: Vapor.Environment
        switch configuration.environment.name {
        case "production": environment = .production
        case "testing", "test": environment = .testing
        default: environment = .development
        }

        let vapor: Vapor.Application
        do {
            vapor = try await Vapor.Application.make(environment)
        } catch {
            throw Server.Error.engine("failed to start application: \(error)")
        }

        vapor.http.server.configuration.hostname = configuration.hostname
        vapor.http.server.configuration.port = configuration.port
        vapor.routes.defaultMaxBodySize = ByteCount(value: configuration.maximumBodySize)

        return Server.Application(vapor: vapor, configuration: configuration)
    }
}

extension Server_Shared.Server.Application {
    /// Registers discrete routes (the lightweight `Server.Route` model) on the engine's router.
    /// Use for endpoints wired individually — webhooks, well-known documents, static handlers.
    public func register(_ routes: [Server_Shared.Server.Route]) {
        for route in routes {
            let respond = route.respond
            vapor.on(route.method.vapor, route.path.map { PathComponent(stringLiteral: $0) }) {
                (vaporRequest: Vapor.Request) async -> Vapor.Response in
                await Server.Application.dispatch(vaporRequest, to: respond)
            }
        }
    }

    /// Serves a pointfree-style router: `decode` turns each request into the consumer's route
    /// value, `respond` turns that route value into a response, and `middleware` wraps the pair.
    /// The membrane never parses URLs itself — a catch-all forwards every request to `decode`.
    ///
    /// Blocks until the server shuts down.
    public func run<Route: Sendable>(
        middleware: [any Server_Shared.Server.Middleware] = [],
        configure: @Sendable (Server_Shared.Server.Application) async throws(Server_Shared.Server.Error) -> Void = { _ in },
        decode: @escaping @Sendable (Server_Shared.Server.Request) async throws(Server_Shared.Server.Error) -> Route,
        respond: @escaping @Sendable (Route) async throws(Server_Shared.Server.Error) -> Server_Shared.Server.Response
    ) async throws(Server_Shared.Server.Error) {
        try await configure(self)

        let base: Server.Responder = { (request: Server.Request) async throws(Server.Error) -> Server.Response in
            let route = try await decode(request)
            return try await respond(route)
        }
        let responder = middleware.chain(around: base)

        for method in Server.Method.allCases {
            vapor.on(method.vapor, "**") { (vaporRequest: Vapor.Request) async -> Vapor.Response in
                await Server.Application.dispatch(vaporRequest, to: responder)
            }
        }

        do {
            try await vapor.execute()
        } catch {
            throw Server.Error.engine("server execution failed: \(error)")
        }
    }

    /// Gracefully shuts the application down.
    public func shutdown() async throws(Server_Shared.Server.Error) {
        do {
            try await vapor.asyncShutdown()
        } catch {
            throw Server.Error.engine("shutdown failed: \(error)")
        }
    }

    /// Bridges an engine request through a responder and back to an engine response, mapping a
    /// thrown `Server.Error` onto its status so the handler never leaks an error to the engine.
    private static func dispatch(
        _ vaporRequest: Vapor.Request,
        to responder: Server.Responder
    ) async -> Vapor.Response {
        let request = Server.Request(vaporRequest)
        let response: Server.Response
        do {
            response = try await responder(request)
        } catch {
            response = Server.Response(
                status: error.status,
                headers: ["Content-Type": "text/plain; charset=utf-8"],
                body: Array(error.message.utf8)
            )
        }
        return response.vapor()
    }
}
