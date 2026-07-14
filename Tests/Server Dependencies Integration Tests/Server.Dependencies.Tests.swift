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

// MARK: - The `\.server` container (the destination of the `\.request` migration)

@Test func `server container defaults to no ambient request`() {
    withDependencies { _ in } operation: {
        @Dependency(\.server.request) var request
        #expect(request == nil)
    }
}

@Test func `server container round-trips through withDependencies`() {
    let injected = Server.Request(method: .get, path: ["analytics", "user"], body: Array("body".utf8))
    withDependencies {
        $0.server.request = injected
    } operation: {
        @Dependency(\.server.request) var request
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

@Test func `middleware binds BOTH the container and the flat key to the same request`() async throws {
    // THE MIGRATION'S LOAD-BEARING GUARANTEE. The ecosystem moves from `\.request` to
    // `\.server.request` one repo at a time, so for the duration of the migration both spellings are
    // live and a consumer on either one must observe the SAME request.
    let base: Server.Responder = { _ in
        @Dependency(\.server.request) var viaContainer
        @Dependency(\.request) var viaFlatKey

        #expect(viaContainer?.pathString == "/webhook/stripe")
        #expect(viaFlatKey?.pathString == "/webhook/stripe")
        #expect(viaContainer?.pathString == viaFlatKey?.pathString)

        return .text(viaContainer?.pathString ?? "<none>")
    }
    let responder = [Server.Dependencies.Middleware() as any Server.Middleware].chain(around: base)

    let response = try await responder(Server.Request(method: .get, path: ["webhook", "stripe"]))
    #expect(String(decoding: response.body, as: UTF8.self) == "/webhook/stripe")
}

@Test func `the flat key is an ALIAS onto the container, so the two cannot diverge`() {
    let viaFlat = Server.Request(method: .get, path: ["flat"])
    let viaContainer = Server.Request(method: .get, path: ["container"])

    // Writing the FLAT key is observed through the CONTAINER…
    withDependencies {
        $0.request = viaFlat
    } operation: {
        @Dependency(\.server.request) var request
        #expect(request?.pathString == "/flat")
    }

    // …and writing the CONTAINER is observed through the FLAT key.
    withDependencies {
        $0.server.request = viaContainer
    } operation: {
        @Dependency(\.request) var request
        #expect(request?.pathString == "/container")
    }
}

@Test func `a NESTED override on either spelling shadows both`() {
    // This is the case a two-key design would have got WRONG, and it is why the flat key forwards
    // instead of carrying its own storage.
    //
    // Writers exist in repos this seat does not own (the app's session authenticator; the identity
    // provider's middleware). With two independent keys, a nested override that set only `\.request`
    // would leave `\.server.request` holding the STALE OUTER value — so a migrated read inside that
    // scope would see the wrong request, silently, while compiling perfectly.
    //
    // One storage slot makes that unrepresentable. Both spellings shadow together, either way round.
    let outer = Server.Request(method: .get, path: ["outer"])
    let inner = Server.Request(method: .get, path: ["inner"])

    // CASE 3 — nested override on the FLAT spelling, read through the CONTAINER.
    // This is the live one: the app's session authenticator and the identity provider's middleware
    // both override `$0.request` in a NESTED scope, and neither is a repo this seat may enter.
    withDependencies {
        $0.server.request = outer
    } operation: {
        withDependencies {
            $0.request = inner
        } operation: {
            @Dependency(\.server.request) var viaContainer
            @Dependency(\.request) var viaFlatKey
            #expect(viaContainer?.pathString == "/inner")  // NOT "/outer" — the whole safety case
            #expect(viaFlatKey?.pathString == "/inner")
        }

        // And the outer scope is intact afterwards.
        @Dependency(\.server.request) var request
        #expect(request?.pathString == "/outer")
    }

    // CASE 4 — the mirror: nested override on the CONTAINER, read through the FLAT spelling.
    // Guards the un-migrated repos: once a writer moves to `$0.server.request`, every call site still
    // reading `@Dependency(\.request)` must keep seeing the override.
    withDependencies {
        $0.request = outer
    } operation: {
        withDependencies {
            $0.server.request = inner
        } operation: {
            @Dependency(\.request) var viaFlatKey
            @Dependency(\.server.request) var viaContainer
            #expect(viaFlatKey?.pathString == "/inner")
            #expect(viaContainer?.pathString == "/inner")
        }

        @Dependency(\.request) var request
        #expect(request?.pathString == "/outer")
    }
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
