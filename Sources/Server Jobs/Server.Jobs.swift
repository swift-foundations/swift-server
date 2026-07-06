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
    /// The background-jobs membrane: job and scheduled-job abstractions over vapor/queues, with a
    /// Redis backend and optional in-process worker execution.
    ///
    /// Models the first consumer's three jobs — an hourly scheduled poll, a scheduled cache
    /// refresh, and on-demand queued bulk work — as ``Server/Jobs/Job`` (payload-carrying,
    /// dispatched) and ``Server/Jobs/Scheduled`` (cadence-owning) conformers accumulated in a
    /// ``Server/Jobs/Registry`` and installed onto a running `Server.Application`.
    public enum Jobs {}
}
