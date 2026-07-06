# swift-server

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

The server-runtime **membrane** for the Swift Institute ecosystem — a thin package that quarantines external server engines (Vapor, PostgresNIO, vapor/queues, AsyncHTTPClient) behind an institute-shaped, largely Foundation-free public surface. Consumer apps import only this package for transport, persistence execution, background jobs, and outbound HTTP; later versions swap the engines for institute-native transports **without changing the surface**.

> **Private, active development.** This package is an external-engine membrane, not a pure Layer-3 foundation yet: today it wraps Vapor / PostgresNIO / AsyncHTTPClient internally, and the institute-native engines are aspirational. Public type names may change in 0.x.

---

## Why a membrane

The institute's five-layer architecture forbids leaking third-party engine types across a package boundary. `swift-server` is the single seam where the outside world's server stack is allowed in — and it is only allowed in *internally*. Every engine is an `internal import`; the public surface is `Server.*` value types with typed throws. When an institute-native transport is ready, it replaces the engine behind an unchanged surface, and no consumer recompiles against a new API.

---

## Products

| Product | Import | Wraps (internal) | Surface |
|---------|--------|------------------|---------|
| **Server** | `import Server` | Vapor | `Server.Application` lifecycle, `Server.Configuration`, `Server.Environment`, `Server.Route` registration + a pointfree-style route seam, `Server.Request` / `Server.Response`, `Server.Middleware` |
| **Server PostgreSQL** | `import Server_PostgreSQL` | PostgresNIO | `Server.PostgreSQL.Executor` (`execute` / `fetchAll` / `fetchOne` / `transaction` / `withRollback`), `Server.PostgreSQL.Migrator` |
| **Server Jobs** | `import Server_Jobs` | vapor/queues (+ Redis driver) | `Server.Jobs.Job`, `Server.Jobs.Scheduled`, `Server.Jobs.Schedule`, `Server.Jobs.Registry`, `Server.Jobs.Driver` |
| **Server HTTP Client** | `import Server_HTTP_Client` | async-http-client | `Server.HTTP.Client`, `Server.HTTP.Request`, `Server.HTTP.Response` |

All four nest under a single `Server` namespace, shared via an internal `Server Shared` target so that a PostgreSQL-only or HTTP-only consumer does not transitively pull Vapor.

---

## Quick Start

```swift
import Server

// A route model your handler switches over — the membrane never parses URLs itself;
// you supply a decode seam (e.g. a pointfree-style URLRouting router) and a responder.
enum Route: Sendable { case home, health }

let application = try await Server.Application(
    configuration: .init(environment: .detect())
)

try await application.run(
    decode: { request in request.path == ["health"] ? .health : .home },
    respond: { route in
        switch route {
        case .home:   .html("<h1>Hello</h1>")
        case .health: .json(#"{"status":"ok"}"#)
        }
    }
)
```

Every throwing operation on the surface uses **typed throws** — `Server.Error`, `Server.PostgreSQL.Error`, `Server.Jobs.Error`, `Server.HTTP.Error` — so no `any Error` escapes the membrane.

---

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/swift-foundations/swift-server.git", branch: "main")
]
```

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "Server", package: "swift-server"),
        .product(name: "Server PostgreSQL", package: "swift-server"),
        .product(name: "Server Jobs", package: "swift-server"),
        .product(name: "Server HTTP Client", package: "swift-server"),
    ]
)
```

### Requirements

- Swift 6.3+
- macOS 26+

---

## Scope (v0)

- The public surface is derived **call-site-first** from the first consumer (`repotraffic-com-server`); see `Research/consumer-call-site-inventory.md`.
- The PostgreSQL executor couples to the Structured Queries DSL through a small protocol seam (`Server.PostgreSQL.Statement`), so the package stays resolvable even while `swift-postgresql-standard` is unresolvable in the ecosystem graph. See the inventory's CONTINGENCY note.
- No live-service integration tests ship in v0 (no Postgres / Redis in CI); unit tests cover the route model, response building, migration ordering, the job registry, and request building.

---

## License

Apache 2.0. See [LICENSE.md](LICENSE.md) for details.
