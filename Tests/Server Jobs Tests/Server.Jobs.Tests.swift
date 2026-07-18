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

import Scheduler
import Server
import Testing

// The first consumer's three jobs, modeled against the L3 Scheduler interface that `Server Jobs`
// is the vapor/queues Live conformance of: on-demand bulk work (payload), and two scheduled jobs.

private struct BulkTrackJob: Scheduler.Job {}

extension BulkTrackJob {
    struct Payload: Codable, Sendable {
        let identityId: String
        let statusId: String
    }
    func run(_ payload: Payload) async throws(Scheduler.Error) {}
}

private struct PollJob: Scheduler.Scheduled {}

extension PollJob {
    static var schedule: Scheduler.Schedule { .hourly(minute: 0) }
    func run() async throws(Scheduler.Error) {}
}

private struct CacheRefreshJob: Scheduler.Scheduled {}

extension CacheRefreshJob {
    static var schedule: Scheduler.Schedule { .hourly(minute: 5) }
    func run() async throws(Scheduler.Error) {}
}

// MARK: - Default names

@Test func `job Name Defaults To Type Name`() {
    #expect(BulkTrackJob.name == "BulkTrackJob")
    #expect(PollJob.name == "PollJob")
}

// MARK: - Schedule

@Test func `schedule Equatable Cases`() {
    #expect(Scheduler.Schedule.hourly(minute: 5) == .hourly(minute: 5))
    #expect(Scheduler.Schedule.hourly(minute: 0) != .hourly(minute: 5))
    #expect(PollJob.schedule == .hourly(minute: 0))
    #expect(CacheRefreshJob.schedule == .hourly(minute: 5))
}

// MARK: - Registry accumulation (pure — no engine)

@Test func `registry Starts Empty`() {
    let registry = Scheduler.Registry()
    #expect(registry.count == 0)
    #expect(registry.jobNames.isEmpty)
    #expect(registry.scheduledNames.isEmpty)
}

@Test func `registry Accumulates Jobs And Schedules`() {
    var registry = Scheduler.Registry()
    registry.register(BulkTrackJob())
    registry.schedule(PollJob())
    registry.schedule(CacheRefreshJob())
    #expect(registry.jobNames == ["BulkTrackJob"])
    #expect(registry.scheduledNames == ["PollJob", "CacheRefreshJob"])
    #expect(registry.count == 3)
}

// MARK: - Driver / Execution vocabulary

@Test func `driver And Execution Cases`() {
    #expect(Scheduler.Driver.redis(url: "redis://localhost:6379") == .redis(url: "redis://localhost:6379"))
    #expect(Scheduler.Execution.inProcess != .workers)
}

@Test func `application Registers And Dispatches Jobs`() async throws {
    var registry = Scheduler.Registry()
    registry.register(BulkTrackJob())
    let application = Server.Application()
    application.register(registry)
    try await application.dispatch(BulkTrackJob.self, .init(identityId: "id", statusId: "status"))
}
