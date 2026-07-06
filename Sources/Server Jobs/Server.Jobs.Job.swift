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
    /// An on-demand job: a `Codable` payload plus the work to run when it is dequeued.
    ///
    /// Mirrors the first consumer's `AutoTrackAllReposJob` — a job dispatched with a typed payload
    /// (an identity and a status id) and processed by a worker. Register with
    /// ``Server/Jobs/Registry`` and enqueue with `Server.Application.dispatch(_:_:)`.
    public protocol Job: Sendable {
        associatedtype Payload: Codable & Sendable
        /// The stable name used to key this job on the queue. Defaults to the type name.
        static var name: String { get }
        /// Runs the job for a dequeued payload.
        func run(_ payload: Payload) async throws(Server.Jobs.Error)
    }
}

extension Server.Jobs.Job {
    public static var name: String { "\(Self.self)" }
}
