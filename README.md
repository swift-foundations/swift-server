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

## License

Apache 2.0. See [LICENSE.md](LICENSE.md) for details.
