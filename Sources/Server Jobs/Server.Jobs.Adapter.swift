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

extension Server.Jobs {
    /// Internal namespace for the type-erasing adapters that bridge institute jobs onto the
    /// engine's `AsyncJob` / `AsyncScheduledJob` protocols.
    enum Adapter {}
}
