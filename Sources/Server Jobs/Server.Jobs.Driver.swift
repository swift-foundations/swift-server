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
    /// The queue backend. v0 offers the Redis driver, matching the first consumer; the underlying
    /// engine ships no in-memory production driver, so in-process *execution* (see
    /// ``Server/Jobs/Execution``) still runs against a Redis backend.
    public enum Driver: Sendable, Hashable {
        case redis(url: String)
    }
}
