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

extension Server {
    /// The opt-in `swift-dependencies` integration for `Server`: the membrane vends the ambient
    /// request/logger dependency keys and the per-request injection seam here, so the engine-free
    /// core (`Server`) never imports `Dependencies` and never leaks an engine type through a
    /// dependency surface.
    ///
    /// ## What this module provides
    ///
    /// - ``Dependency/Values/request`` — the ambient ``Server/Request`` for the in-flight request,
    ///   or `nil` outside a request scope. It is the membrane type, **not** `Vapor.Request`.
    /// - ``Dependency/Values/logger`` — the ambient `Logging.Logger`. `swift-log` is the
    ///   SSWG-standard structured-logging façade, an interface type designed to cross module
    ///   boundaries; it carries no Vapor/NIO engine type, so vending it directly (rather than
    ///   behind an institute-local facade) is membrane-clean and gives the consumer drop-in parity
    ///   with `@Dependency(\.logger)`.
    /// - ``Server/Dependencies/Middleware`` — the per-request injection seam: a `Server.Middleware`
    ///   the consumer installs so every inbound request runs its responder inside
    ///   `withDependencies { $0.request = …; $0.logger = … }`.
    ///
    /// ## Boot-harness parity (design note for the app-cutover wave)
    ///
    /// This target deliberately stops at the request-scoped injection seam; it does **not** ship a
    /// `Boiler.execute`-style boot harness. The intended parity for the app cutover is:
    ///
    /// 1. **Boot scope.** At application boot the consumer establishes the process-wide baseline
    ///    with a single `withDependencies { $0.logger = bootLogger; … } operation: { try await
    ///    application.run(…) }` wrapping the whole serve loop — mirroring how `Boiler.execute`
    ///    seeds the graph before serving. Long-lived dependencies (database, logger label, router)
    ///    are set once here.
    /// 2. **Request scope.** ``Server/Dependencies/Middleware``, installed first in the middleware
    ///    stack passed to `application.run(middleware:…)`, layers the per-request overrides
    ///    (`\.request`, a request-scoped `\.logger`) inside the boot scope for the duration of each
    ///    responder invocation. The two scopes compose: the request scope inherits every boot-scope
    ///    value and shadows only what it re-assigns.
    ///
    /// The app-cutover wave consumes this note to build the boot wrapper; nothing in this module
    /// presumes a specific boot entry point, so it stays engine- and application-agnostic.
    public enum Dependencies {}
}
