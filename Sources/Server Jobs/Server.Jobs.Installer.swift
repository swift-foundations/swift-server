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

internal import Queues
internal import Scheduler
internal import Server_Shared
internal import Vapor

private typealias Server = Server_Shared.Server

extension Server.Jobs {
    /// The ``Scheduler/Installing`` conformer for the vapor/queues backing. Holds the running Vapor
    /// `Application` and converts each typed job or scheduled job the registry replays into the
    /// Queues adapters — exactly as the relocated `Server.Jobs.Registry` entries did, but now
    /// receiving the concrete job type (and its `Payload`) directly through the erasure seam rather
    /// than through captured closures. Kept internal so no engine type escapes the membrane.
    final class Installer: Scheduler.Installing {
        let application: Vapor.Application

        init(application: Vapor.Application) {
            self.application = application
        }
    }
}

extension Server.Jobs.Installer {
    func install<J: Scheduler.Job>(_ job: J) {
        application.queues.add(Server.Jobs.Adapter.Job(wrapped: job))
    }

    func install<S: Scheduler.Scheduled>(_ scheduled: S) {
        let builder = application.queues.schedule(Server.Jobs.Adapter.Scheduled(wrapped: scheduled))
        S.schedule.apply(to: builder)
    }
}
