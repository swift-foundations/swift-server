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
    /// The typed error domain thrown by job registration, dispatch, and execution.
    public enum Error: Swift.Error, Sendable {
        /// Configuring the queue driver failed (e.g. an invalid Redis URL).
        case driver(String)
        /// Dispatching a job onto the queue failed.
        case dispatch(String)
        /// Starting the in-process workers failed.
        case execution(String)
        /// A job's `run` failed; the string carries the underlying description.
        case run(String)
    }
}
