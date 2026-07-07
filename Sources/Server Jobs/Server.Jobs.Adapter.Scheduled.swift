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

extension Server.Jobs.Adapter {
    /// Bridges a ``Scheduler/Scheduled`` onto the engine's `AsyncScheduledJob`.
    struct Scheduled<Wrapped: Scheduler.Scheduled> {
        let wrapped: Wrapped

        init(wrapped: Wrapped) {
            self.wrapped = wrapped
        }
    }
}

extension Server.Jobs.Adapter.Scheduled: AsyncScheduledJob {
    // Signature forced by external protocol Queues.AsyncScheduledJob (untyped throws).
    // swiftlint:disable:next typed_throws_required
    func run(context: QueueContext) async throws {
        try await wrapped.run()
    }
}
