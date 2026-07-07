// swift-tools-version: 6.3.1

import PackageDescription

let package = Package(
    name: "swift-server",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .library(name: "Server", targets: ["Server"]),
        .library(name: "Server PostgreSQL", targets: ["Server PostgreSQL"]),
        .library(name: "Server Jobs", targets: ["Server Jobs"]),
        .library(name: "Server HTTP Client", targets: ["Server HTTP Client"]),
    ],
    dependencies: [
        // External server engines — quarantined behind the membrane, imported internally only.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.106.0"),
        .package(url: "https://github.com/vapor/postgres-nio.git", from: "1.22.0"),
        .package(url: "https://github.com/vapor/queues.git", from: "1.17.0"),
        .package(url: "https://github.com/vapor/queues-redis-driver.git", from: "1.1.0"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.21.0"),
        // Both are already in the transitive graph via the engines above; declared explicitly
        // per [PKG-DEP-003] because the PostgreSQL executor imports them directly.
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.0"),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.20.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
        // Institute L2/L3 vocabulary — the chassis imports these instead of re-declaring them
        // (institute-server-stack-architecture.md Q1/Q3: dissolve `Server Shared`'s re-declared
        // HTTP vocabulary in favor of the RFC 9110 family; swap `Server.Environment` for L3
        // swift-environment).
        .package(url: "https://github.com/swift-standards/swift-http-standard.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-environment.git", branch: "main"),
        // Institute L3 persistence interfaces. `Server PostgreSQL` is the PostgresNIO Live
        // conformance of these engine-free surfaces (institute-server-stack-architecture.md Q2–Q4):
        // the executor conforms to `SQL.Database`, and migrations run via `SQL.Migrator`.
        .package(url: "https://github.com/swift-foundations/swift-sql.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-migrations.git", branch: "main"),
    ],
    targets: [
        // MARK: - Server Shared (internal namespace + the institute L2 HTTP vocabulary re-export)

        .target(
            name: "Server Shared",
            dependencies: [
                .product(name: "HTTP Standard", package: "swift-http-standard")
            ],
            path: "Sources/Server Shared"
        ),

        // MARK: - Server (core: Vapor bootstrap, lifecycle, routing seam, request/response)

        .target(
            name: "Server",
            dependencies: [
                "Server Shared",
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Environment", package: "swift-environment"),
            ],
            path: "Sources/Server"
        ),

        // MARK: - Server PostgreSQL (statement executor + migrator over PostgresNIO)

        .target(
            name: "Server PostgreSQL",
            dependencies: [
                "Server Shared",
                .product(name: "SQL", package: "swift-sql"),
                .product(name: "Migrations", package: "swift-migrations"),
                .product(name: "PostgresNIO", package: "postgres-nio"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "NIOSSL", package: "swift-nio-ssl"),
            ],
            path: "Sources/Server PostgreSQL"
        ),

        // MARK: - Server Jobs (job + scheduled-job abstractions over vapor/queues)

        .target(
            name: "Server Jobs",
            dependencies: [
                "Server Shared",
                "Server",
                .product(name: "Queues", package: "queues"),
                .product(name: "QueuesRedisDriver", package: "queues-redis-driver"),
                .product(name: "NIOCore", package: "swift-nio"),
            ],
            path: "Sources/Server Jobs"
        ),

        // MARK: - Server HTTP Client (outbound HTTP over async-http-client)

        .target(
            name: "Server HTTP Client",
            dependencies: [
                "Server Shared",
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
            ],
            path: "Sources/Server HTTP Client"
        ),

        // MARK: - Tests

        .testTarget(
            name: "Server Tests",
            dependencies: ["Server", "Server Shared"],
            path: "Tests/Server Tests"
        ),
        .testTarget(
            name: "Server PostgreSQL Tests",
            dependencies: [
                "Server PostgreSQL",
                "Server Shared",
                .product(name: "SQL", package: "swift-sql"),
                .product(name: "SQL Test Support", package: "swift-sql"),
            ],
            path: "Tests/Server PostgreSQL Tests"
        ),
        .testTarget(
            name: "Server Jobs Tests",
            dependencies: ["Server Jobs", "Server Shared"],
            path: "Tests/Server Jobs Tests"
        ),
        .testTarget(
            name: "Server HTTP Client Tests",
            dependencies: ["Server HTTP Client", "Server Shared"],
            path: "Tests/Server HTTP Client Tests"
        ),
    ],
    swiftLanguageModes: [.v6]
)

// Membrane build settings. This package deliberately runs a *pragmatic* subset of the
// institute ecosystem SwiftSettings rather than the full primitives-strict bundle:
// wrapping heavyweight external engines (Vapor / PostgresNIO / Queues / AsyncHTTPClient)
// under strictMemorySafety / StrictUnsafe generates friction with no membrane benefit.
// The membrane-critical setting is InternalImportsByDefault — it makes every engine
// `import` internal by default, so the compiler REFUSES to let an engine type escape
// through the public surface. That is the enforcement that keeps the membrane honest.
for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let membrane: [SwiftSetting] = [
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("ExistentialAny"),
    ]
    target.swiftSettings = (target.swiftSettings ?? []) + membrane
}
