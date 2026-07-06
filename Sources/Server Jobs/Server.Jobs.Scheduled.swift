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

extension Server.Jobs {
    /// A scheduled job: a cadence plus the work to run on each tick.
    ///
    /// Mirrors the first consumer's `GitHubPollingJob` (hourly at `:00`) and `CacheRefreshJob`
    /// (hourly at `:05`) — jobs that own their cadence and take no payload.
    public protocol Scheduled: Sendable {
        /// The stable name of this scheduled job. Defaults to the type name.
        static var name: String { get }
        /// The cadence at which the job runs.
        static var schedule: Server.Jobs.Schedule { get }
        /// Runs the job for one scheduled tick.
        func run() async throws(Server.Jobs.Error)
    }
}

extension Server.Jobs.Scheduled {
    public static var name: String { "\(Self.self)" }
}
