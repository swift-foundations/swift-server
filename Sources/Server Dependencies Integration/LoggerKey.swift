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

public import Dependencies
public import Logging

/// The dependency key backing ``Dependency/Values/logger``. The live value is a plainly-labelled
/// `Logger`; the test value swallows output through `SwiftLogNoOpLogHandler` so scripted tests stay
/// silent. `swift-log` is the SSWG structured-logging façade — a boundary-crossing interface type,
/// not a Vapor/NIO engine type — so vending it on the public surface is membrane-clean.
private enum LoggerKey: Dependency.Key {}

extension LoggerKey {
    static let liveValue: Logging.Logger = Logger(label: "server")
    static let testValue: Logging.Logger = Logger(label: "server", factory: { _ in
        SwiftLogNoOpLogHandler()
    })
}

extension Dependency.Values {
    /// The ambient `Logging.Logger`. Defaults to a `"server"`-labelled logger; wire a boot logger
    /// with `withDependencies { $0.logger = … }`, and let ``Server/Dependencies/Middleware`` layer
    /// a request-scoped logger per inbound request. Consumers read it with
    /// `@Dependency(\.logger) var logger`.
    public var logger: Logging.Logger {
        get { self[LoggerKey.self] }
        set { self[LoggerKey.self] = newValue }
    }
}
