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

extension HTTP.Status {
    /// The engine status for this institute status. `HTTPResponseStatus.init(statusCode:reasonPhrase:)`
    /// discards a custom reason phrase in favor of its own default for status codes it recognizes,
    /// and defaults to `""` (its own synthesized phrase) when none is supplied — `HTTP.Status`'s
    /// `reasonPhrase` is optional, so `nil` maps onto that default rather than an empty phrase.
    var vapor: HTTPResponseStatus {
        HTTPResponseStatus(statusCode: code, reasonPhrase: reasonPhrase ?? "")
    }
}
