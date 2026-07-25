# swift-server

The pure server contracts package for the Swift Institute ecosystem. It owns lifecycle, routing,
middleware, HTTP request/response views, and the Scheduler registration seam without coupling the
product to a server engine.

> **Private, active development.** Public type names may change in 0.x.

## Product

`Server` (`import Server`) provides:

- `Server.Application` lifecycle, route registration, and pure request dispatch
- `Server.Configuration` backed by canonical `Environment.Snapshot`
- `Server.Route`, `Server.Responder`, and `Server.Middleware`
- `Server.Request` and `Server.Response` over the `HTTP Standard` vocabulary
- pure `Scheduler.Registry` registration and typed job dispatch

All contracts nest under one `Server` namespace in one target. HTTP vocabulary is imported directly
from `HTTP Standard`; there is no compatibility or re-export target.

## Quick start

```swift
import Server

let application = Server.Application()
try await application.run(
    decode: { $0.path },
    respond: { _ in .text("ok") }
)
```

Every throwing operation uses typed throws: `Server.Error` or `Scheduler.Error`.

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/swift-foundations/swift-server.git", branch: "main")
]
```

```swift
.target(
    name: "YourTarget",
    dependencies: [.product(name: "Server", package: "swift-server")]
)
```

### Requirements

- Swift 6.3+
- macOS 26+

## Error Handling

Every throwing operation on the core transport surface uses typed throws over `Server.Error`.
Each case maps to an HTTP status via `Server.Error.status`, so a handler can translate the domain
into a response uniformly:

```
Server.Error
├── notFound(String)         → 404 Not Found
├── badRequest(String)       → 400 Bad Request
├── unauthorized             → 401 Unauthorized
├── paymentRequired(String)  → 402 Payment Required
├── forbidden(String)        → 403 Forbidden
├── payloadTooLarge          → 413 Content Too Large
├── decoding(String)         → 422 Unprocessable Content
├── notImplemented(String)   → 501 Not Implemented
├── encoding(String)         → 500 Internal Server Error
├── engine(String)           → 500 Internal Server Error
├── unavailable(String)      → 503 Service Unavailable
└── internalError(String)    → 500 Internal Server Error
```

Because the throw is typed, `catch` is exhaustive over the domain — no `default` or unclassified
engine error leaks through the membrane:

```swift
import Server

let application = Server.Application()

do {
    try await application.run(
        decode: { $0.path },
        respond: { _ in .text("ok") }
    )
} catch let error as Server.Error {
    switch error {
    case .notFound(let reason):        print("404 \(reason)")
    case .badRequest(let reason):      print("400 \(reason)")
    case .unauthorized:                print("401 Unauthorized")
    case .paymentRequired(let reason): print("402 \(reason)")
    case .forbidden(let reason):       print("403 \(reason)")
    case .payloadTooLarge:             print("413 Content Too Large")
    case .decoding(let value):         print("422 failed to decode \(value)")
    case .notImplemented(let reason):  print("501 \(reason)")
    case .encoding(let value):         print("500 failed to encode \(value)")
    case .engine(let description):     print("500 engine: \(description)")
    case .unavailable(let service):    print("503 \(service)")
    case .internalError(let desc):     print("500 \(desc)")
    }
}
```

Job dispatch (`Server.Application` scheduling) throws `Scheduler.Error` instead, and the optional
`Server HTML` / `Server JSON` response builders surface their dependency-owned errors
(`HTML.Context.Configuration.Error` from the HTML response seam) — each its own typed domain.

## License

Apache 2.0. See [LICENSE.md](LICENSE.md) for details.
