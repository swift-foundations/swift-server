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

public import Server
public import Server_Shared

internal import Queues
internal import QueuesRedisDriver
internal import NIOCore

// The core membrane target is itself named `Server`, which shadows the `Server_Shared.Server`
// namespace enum when both are in scope. The public surface therefore spells the namespace out.
extension Server_Shared.Server.Application {
    /// Installs a job registry onto the running application: selects the queue driver, registers
    /// every job and scheduled job, and — for `.inProcess` execution — starts the in-process
    /// workers. Mirrors the first consumer's `configureQueues` + `schedulePollingJob` +
    /// `startInProcessJobs()` / `startScheduledJobs()` sequence.
    public func register(
        _ registry: Server_Shared.Server.Jobs.Registry,
        driver: Server_Shared.Server.Jobs.Driver,
        execution: Server_Shared.Server.Jobs.Execution = .workers
    ) throws(Server_Shared.Server.Jobs.Error) {
        switch driver {
        case .redis(let url):
            do {
                vapor.queues.use(try .redis(url: url))
            } catch {
                throw Server_Shared.Server.Jobs.Error.driver("\(error)")
            }
        }

        for installer in registry.installers {
            installer.run(vapor)
        }

        if execution == .inProcess {
            do {
                try vapor.queues.startInProcessJobs()
                try vapor.queues.startScheduledJobs()
            } catch {
                throw Server_Shared.Server.Jobs.Error.execution("\(error)")
            }
        }
    }

    /// Enqueues an on-demand job with its payload onto the default queue.
    public func dispatch<J: Server_Shared.Server.Jobs.Job>(
        _ jobType: J.Type,
        _ payload: J.Payload
    ) async throws(Server_Shared.Server.Jobs.Error) {
        do {
            try await vapor.queues.queue.dispatch(Server_Shared.Server.Jobs.Adapter.Job<J>.self, payload).get()
        } catch {
            throw Server_Shared.Server.Jobs.Error.dispatch("\(error)")
        }
    }
}
