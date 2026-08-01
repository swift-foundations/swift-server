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

public import HTTP_Standard

extension Server {
    /// The engine-neutral application lifecycle and routing contract.
    public final class Application: @unchecked Sendable {
        public let configuration: Server.Configuration
        private var routes: [Server.Route] = []
        private var responder: Server.Responder?
        private var isRunning = false
        var jobInstaller: Server.Jobs.Installer?

        public init(configuration: Server.Configuration = .init()) {
            self.configuration = configuration
        }
    }
}

extension Server.Application {
    public static func make(
        configuration: Server.Configuration = .init()
    ) -> Server.Application {
        Server.Application(configuration: configuration)
    }

    /// Registers literal routes in registration order.
    public func register(_ routes: [Server.Route]) {
        self.routes.append(contentsOf: routes)
    }

    // The middleware collection is intentionally heterogeneous so distinct conformers can be
    // composed in registration order.
    /// Installs the pure responder pipeline and marks the application running.
    ///
    /// A transport backing owns the actual accept loop; this package intentionally owns only
    /// the lifecycle contract and request/response dispatch seam.
    public func run<Route: Sendable>(
        // swiftlint:disable:next no_any_protocol_existential
        middleware: [any Server.Middleware] = [],
        configure: @Sendable (Server.Application) async throws(Server.Error) -> Void = { _ in },
        decode: @escaping @Sendable (Server.Request) async throws(Server.Error) -> Route,
        respond: @escaping @Sendable (Route) async throws(Server.Error) -> Server.Response
    ) async throws(Server.Error) {
        try await configure(self)
        let base: Server.Responder = { request in
            try await respond(try await decode(request))
        }
        responder = middleware.chain(around: base)
        isRunning = true
    }

    /// Dispatches a request through a registered literal route or the installed responder.
    public func response(
        to request: Server.Request
    ) async throws(Server.Error) -> Server.Response {
        guard isRunning else { throw Server.Error.engine("application is not running") }
        if let route = routes.last(where: { $0.method == request.method && $0.path == request.path }) {
            return try await route.respond(request)
        }
        guard let responder else { throw Server.Error.notFound("Not Found") }
        return try await responder(request)
    }

    /// Stops the pure lifecycle contract. Transport backings perform their own teardown.
    public func shutdown() {
        isRunning = false
        responder = nil
    }
}
