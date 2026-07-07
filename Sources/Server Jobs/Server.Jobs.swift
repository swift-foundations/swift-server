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

extension Server {
    /// The vapor/queues Live conformance of the L3 `Scheduler` interface.
    ///
    /// `Scheduler` (swift-scheduler) defines the engine-free jobs surface — `Scheduler.Job`,
    /// `Scheduler.Scheduled`, `Scheduler.Schedule`, `Scheduler.Registry`, and the
    /// `Scheduler.Installing` seam. `Server.Jobs` is the backing that makes it run: internal
    /// adapters bridge a `Scheduler.Job` / `Scheduler.Scheduled` onto the Queues engine's
    /// `AsyncJob` / `AsyncScheduledJob`, and the `Server.Jobs.Installer` conforms to
    /// `Scheduler.Installing` — converting each typed job the registry replays into the Queues
    /// adapters on the running `Server.Application`, with a Redis backend and optional in-process
    /// worker execution. The engine stays quarantined behind this membrane; nothing engine-typed
    /// escapes through the public surface (see `Server.Application` register / dispatch).
    public enum Jobs {}
}
