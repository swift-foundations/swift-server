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

public import Logging
public import Server
public import Server_Shared
private import Dependencies

extension Server.Dependencies {
    /// The per-request injection seam: a ``Server/Middleware`` that runs each responder inside a
    /// `withDependencies` scope binding the ambient ``Dependency/Values/request`` and
    /// ``Dependency/Values/logger``.
    ///
    /// Install it first in the middleware stack passed to `application.run(middleware:…)`, so it is
    /// the outermost layer and every inner middleware and the base responder observe the injected
    /// values via `@Dependency(\.request)` / `@Dependency(\.logger)`. The seam does not touch the
    /// existing pipeline — it is an ordinary middleware folded in by `[any Server.Middleware].chain`.
    public struct Middleware: Server.Middleware {
        /// The base logger bound into each request scope (typically the boot logger). Per request it
        /// is tagged with the request path so log lines are attributable without the responder
        /// threading the request through.
        private let logger: Logging.Logger

        public init(logger: Logging.Logger = Logger(label: "server")) {
            self.logger = logger
        }

        public func intercept(
            _ request: Server.Request,
            next: Server.Responder
        ) async throws(Server.Error) -> Server.Response {
            var requestLogger = logger
            requestLogger[metadataKey: "request.path"] = .string(request.pathString)
            return try await withDependencies {
                // Binding the container binds BOTH spellings: the flat `\.request` is an alias onto
                // `\.server.request`, one storage slot. Consumers still on `@Dependency(\.request)`
                // observe this write unchanged, so nothing breaks while the migration is in flight.
                $0.server.request = request
                $0.logger = requestLogger
            } operation: { () async throws(Server.Error) -> Server.Response in
                try await next(request)
            }
        }
    }
}
