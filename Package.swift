// swift-tools-version: 6.3.3

import PackageDescription

let package = Package(
    name: "swift-server",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .library(name: "Server", targets: ["Server"]),
        // `Server Dependencies` is owned by swift-foundations/swift-server-dependencies
        // (principal ruling 2026-07-28); this package gives the name up entirely, at
        // product level as well as target level. Consumers move to
        // `.product(name: "Server Dependencies Integration", package: "swift-server")`.
        .library(name: "Server Dependencies Integration", targets: ["Server Dependencies Integration"]),
        .library(name: "Server HTML", targets: ["Server HTML"]),
        .library(name: "Server JSON", targets: ["Server JSON"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-foundations/swift-dependencies.git", branch: "main"),
        .package(url: "https://github.com/swift-standards/swift-http-standard.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-byte-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-environment.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-html-render.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-json.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-scheduler.git", branch: "main"),
    ],
    targets: [
        // MARK: - Server (pure lifecycle, routing, request/response, and jobs contracts)

        .target(
            name: "Server",
            dependencies: [
                .product(name: "HTTP Standard", package: "swift-http-standard"),
                .product(name: "Environment", package: "swift-environment"),
                .product(name: "Scheduler", package: "swift-scheduler"),
            ],
            path: "Sources/Server"
        ),

        // MARK: - Dependencies integration (the `\.server.request` scope)

        .target(
            name: "Server Dependencies Integration",
            dependencies: [
                "Server",
                .product(name: "Dependencies", package: "swift-dependencies"),
            ],
            path: "Sources/Server Dependencies"
        ),

        // MARK: - HTML integration

        .target(
            name: "Server HTML",
            dependencies: [
                "Server",
                .product(name: "HTML Rendering Core", package: "swift-html-render"),
            ],
            path: "Sources/Server HTML"
        ),

        // MARK: - JSON integration

        .target(
            name: "Server JSON",
            dependencies: [
                "Server",
                .product(name: "Byte Primitive", package: "swift-byte-primitives"),
                .product(name: "JSON", package: "swift-json"),
            ],
            path: "Sources/Server JSON"
        ),

        // MARK: - Tests

        .testTarget(
            name: "Server Tests",
            dependencies: ["Server", .product(name: "HTTP Standard", package: "swift-http-standard")],
            path: "Tests/Server Tests"
        ),
        .testTarget(
            name: "Server Dependencies Integration Tests",
            dependencies: [
                "Server",
                "Server Dependencies Integration",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "HTTP Standard", package: "swift-http-standard"),
            ],
            path: "Tests/Server Dependencies Tests"
        ),
        .testTarget(
            name: "Server Jobs Tests",
            dependencies: ["Server", .product(name: "Scheduler", package: "swift-scheduler")],
            path: "Tests/Server Jobs Tests"
        ),
        .testTarget(
            name: "Server HTML Tests",
            dependencies: [
                "Server",
                "Server HTML",
                .product(name: "HTML Rendering Core", package: "swift-html-render"),
                .product(name: "HTTP Standard", package: "swift-http-standard"),
            ],
            path: "Tests/Server HTML Tests"
        ),
        .testTarget(
            name: "Server JSON Tests",
            dependencies: [
                "Server",
                "Server JSON",
                .product(name: "HTTP Standard", package: "swift-http-standard"),
                .product(name: "JSON", package: "swift-json"),
            ],
            path: "Tests/Server JSON Tests"
        ),
    ],
    swiftLanguageModes: [.v6]
)

// Build settings keep imported foundation interfaces internal by default and make
// accidental public dependency leakage fail at the declaration boundary.
for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let membrane: [SwiftSetting] = [
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("ExistentialAny"),
    ]
    target.swiftSettings = (target.swiftSettings ?? []) + membrane
}
