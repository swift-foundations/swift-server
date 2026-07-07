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
    /// Bridges a ``Scheduler/Job`` onto the engine's `AsyncJob`, keyed by the wrapped job's name
    /// so registration and dispatch resolve to the same entry.
    struct Job<Wrapped: Scheduler.Job> {
        let wrapped: Wrapped

        init(wrapped: Wrapped) {
            self.wrapped = wrapped
        }
    }
}

extension Server.Jobs.Adapter.Job: AsyncJob {
    static var name: String { Wrapped.name }

    // Signature forced by external protocol Queues.AsyncJob (untyped throws).
    // swiftlint:disable:next typed_throws_required
    func dequeue(_ context: QueueContext, _ payload: Wrapped.Payload) async throws {
        try await wrapped.run(payload)
    }
}
