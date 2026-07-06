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

internal import Vapor

private typealias Server = Server_Shared.Server

extension Server.Jobs.Registry {
    /// An erased registration step: applies one job or scheduled job onto the running engine. Kept
    /// internal so the registry's public surface stays engine-free.
    struct Installer: Sendable {
        let run: @Sendable (Vapor.Application) -> Void
    }
}
