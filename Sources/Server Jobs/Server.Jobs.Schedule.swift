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
    /// When a scheduled job runs.
    ///
    /// Covers the two cadences the first consumer uses: hourly at a given minute (the GitHub poll
    /// at `:00`, the cache refresh at `:05`) and daily at a given time.
    public enum Schedule: Sendable, Hashable {
        /// Every hour, at the given minute past the hour (0–59).
        case hourly(minute: Int)
        /// Every day, at the given hour (0–23) and minute (0–59).
        case daily(hour: Int, minute: Int)
    }
}
