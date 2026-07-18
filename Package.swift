// swift-tools-version: 6.3.3

import PackageDescription

let package = Package(
    name: "swift-server",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .library(name: "Server", targets: ["Server"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-standards/swift-http-standard.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-environment.git", branch: "main"),
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

        // MARK: - Tests

        .testTarget(
            name: "Server Tests",
            dependencies: ["Server", .product(name: "HTTP Standard", package: "swift-http-standard")],
            path: "Tests/Server Tests"
        ),
        .testTarget(
            name: "Server Jobs Tests",
            dependencies: ["Server", .product(name: "Scheduler", package: "swift-scheduler")],
            path: "Tests/Server Jobs Tests"
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
