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

extension Server.PostgreSQL {
    /// The typed error domain thrown by the executor and migrator.
    public enum Error: Swift.Error, Sendable {
        /// Connecting to or acquiring a connection from the database failed.
        case connection(String)
        /// A statement failed to execute; the string carries the engine's description.
        case execution(String)
        /// A column could not be decoded into the requested type.
        case decoding(String)
        /// A transaction could not be run (e.g. attempted on a connection-scoped executor).
        case transaction(String)
        /// A migration failed; the string names the migration.
        case migration(String)
    }
}
