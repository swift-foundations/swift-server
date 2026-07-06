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

internal import Server_Shared

internal import Queues

extension Server.Jobs.Adapter {
    /// Bridges a ``Server/Jobs/Scheduled`` onto the engine's `AsyncScheduledJob`.
    struct Scheduled<Wrapped: Server.Jobs.Scheduled> {
        let wrapped: Wrapped

        init(wrapped: Wrapped) {
            self.wrapped = wrapped
        }
    }
}

extension Server.Jobs.Adapter.Scheduled: AsyncScheduledJob {
    func run(context: QueueContext) async throws {
        try await wrapped.run()
    }
}
