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

import Testing

import Server_Jobs
import Server_Shared

// The first consumer's three jobs, modeled: on-demand bulk work (payload), and two scheduled jobs.

private struct BulkTrackJob: Server.Jobs.Job {
    struct Payload: Codable, Sendable {
        let identityId: String
        let statusId: String
    }
    func run(_ payload: Payload) async throws(Server.Jobs.Error) {}
}

private struct PollJob: Server.Jobs.Scheduled {
    static var schedule: Server.Jobs.Schedule { .hourly(minute: 0) }
    func run() async throws(Server.Jobs.Error) {}
}

private struct CacheRefreshJob: Server.Jobs.Scheduled {
    static var schedule: Server.Jobs.Schedule { .hourly(minute: 5) }
    func run() async throws(Server.Jobs.Error) {}
}

// MARK: - Default names

@Test func jobNameDefaultsToTypeName() {
    #expect(BulkTrackJob.name == "BulkTrackJob")
    #expect(PollJob.name == "PollJob")
}

// MARK: - Schedule

@Test func scheduleEquatableCases() {
    #expect(Server.Jobs.Schedule.hourly(minute: 5) == .hourly(minute: 5))
    #expect(Server.Jobs.Schedule.hourly(minute: 0) != .hourly(minute: 5))
    #expect(PollJob.schedule == .hourly(minute: 0))
    #expect(CacheRefreshJob.schedule == .hourly(minute: 5))
}

// MARK: - Registry accumulation (pure — no engine)

@Test func registryStartsEmpty() {
    let registry = Server.Jobs.Registry()
    #expect(registry.count == 0)
    #expect(registry.jobNames.isEmpty)
    #expect(registry.scheduledNames.isEmpty)
}

@Test func registryAccumulatesJobsAndSchedules() {
    var registry = Server.Jobs.Registry()
    registry.register(BulkTrackJob())
    registry.schedule(PollJob())
    registry.schedule(CacheRefreshJob())
    #expect(registry.jobNames == ["BulkTrackJob"])
    #expect(registry.scheduledNames == ["PollJob", "CacheRefreshJob"])
    #expect(registry.count == 3)
}

// MARK: - Driver / Execution vocabulary

@Test func driverAndExecutionCases() {
    #expect(Server.Jobs.Driver.redis(url: "redis://localhost:6379") == .redis(url: "redis://localhost:6379"))
    #expect(Server.Jobs.Execution.inProcess != .workers)
}
