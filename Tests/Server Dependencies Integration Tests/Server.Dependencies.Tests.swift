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

import Dependencies
import Logging
import Server
import Server_Dependencies_Integration
import Server_Shared
import Testing

// MARK: - Dependency keys

@Test func `request key defaults to nil`() {
    withDependencies { _ in } operation: {
        @Dependency(\.request) var request
        #expect(request == nil)
    }
}

@Test func `request key round-trips through withDependencies`() {
    let injected = Server.Request(method: .get, path: ["analytics", "user"], body: Array("body".utf8))
    withDependencies {
        $0.request = injected
    } operation: {
        @Dependency(\.request) var request
        #expect(request?.pathString == "/analytics/user")
        #expect(request?.method == .get)
        #expect(request?.bodyString == "body")
    }
}

@Test func `logger key has a default and round-trips`() {
    withDependencies { _ in } operation: {
        @Dependency(\.logger) var logger
        #expect(logger.label == "server")
    }
    withDependencies {
        $0.logger = Logger(label: "custom")
    } operation: {
        @Dependency(\.logger) var logger
        #expect(logger.label == "custom")
    }
}

// MARK: - Injection seam (Server.Dependencies.Middleware)

@Test func `middleware injects ambient request into the responder`() async throws {
    // A base responder that reads the ambient request and echoes its path — proving the middleware
    // established the `\.request` scope before `next` ran.
    let base: Server.Responder = { _ in
        @Dependency(\.request) var request
        return .text(request?.pathString ?? "<none>")
    }
    let middleware: [any Server.Middleware] = [Server.Dependencies.Middleware()]
    let responder = middleware.chain(around: base)

    let request = Server.Request(method: .get, path: ["webhook", "stripe"])
    let response = try await responder(request)
    #expect(String(decoding: response.body, as: UTF8.self) == "/webhook/stripe")
}

@Test func `middleware injects a request-scoped logger tagged with the path`() async throws {
    let base: Server.Responder = { _ in
        @Dependency(\.logger) var logger
        let path = logger[metadataKey: "request.path"].map { "\($0)" } ?? "<none>"
        return .text(path)
    }
    let responder = [Server.Dependencies.Middleware() as any Server.Middleware].chain(around: base)

    let response = try await responder(Server.Request(method: .get, path: ["api", "health"]))
    #expect(String(decoding: response.body, as: UTF8.self) == "/api/health")
}

@Test func `ambient request is absent outside the middleware scope`() async throws {
    // Without the injection middleware, the base responder sees no ambient request.
    let base: Server.Responder = { _ in
        @Dependency(\.request) var request
        return .text(request == nil ? "nil" : "present")
    }
    let response = try await base(Server.Request(method: .get, path: []))
    #expect(String(decoding: response.body, as: UTF8.self) == "nil")
}
