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

internal import Queues

extension Server.Jobs {
    /// Accumulates the jobs and scheduled jobs an application should run, then installs them onto a
    /// running `Server.Application`. Its public surface (``register(_:)`` / ``schedule(_:)`` /
    /// ``jobNames`` / ``scheduledNames``) is engine-free; the erased installers it holds are
    /// internal.
    public struct Registry: Sendable {
        /// The names of registered on-demand jobs, in registration order.
        public private(set) var jobNames: [String]
        /// The names of registered scheduled jobs, in registration order.
        public private(set) var scheduledNames: [String]
        var installers: [Server.Jobs.Registry.Installer]

        public init() {
            self.jobNames = []
            self.scheduledNames = []
            self.installers = []
        }
    }
}

extension Server.Jobs.Registry {
    /// The total number of registered jobs (on-demand plus scheduled). Pure — testable.
    public var count: Int { jobNames.count + scheduledNames.count }

    /// Registers an on-demand job.
    public mutating func register<J: Server.Jobs.Job>(_ job: J) {
        jobNames.append(J.name)
        installers.append(
            Server.Jobs.Registry.Installer { application in
                application.queues.add(Server.Jobs.Adapter.Job(wrapped: job))
            }
        )
    }

    /// Registers a scheduled job at its declared cadence.
    public mutating func schedule<J: Server.Jobs.Scheduled>(_ job: J) {
        scheduledNames.append(J.name)
        let schedule = J.schedule
        installers.append(
            Server.Jobs.Registry.Installer { application in
                let builder = application.queues.schedule(Server.Jobs.Adapter.Scheduled(wrapped: job))
                schedule.apply(to: builder)
            }
        )
    }
}
