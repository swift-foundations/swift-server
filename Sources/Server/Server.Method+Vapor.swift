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

// Both `HTTP.Method` (RFC 9110, open method set) and `Vapor.HTTPMethod` (NIOHTTP1, `RawRepresentable`
// with a `.RAW(value:)` catch-all case) are String-keyed open sets, so the bridge is a lossless
// rawValue round-trip — no default-to-`.get` fallback needed, unlike the dissolved prototype's
// closed 7-case enum.
extension HTTP.Method {
    /// The engine method for this institute method.
    var vapor: HTTPMethod {
        HTTPMethod(rawValue: rawValue)
    }

    /// Maps an engine method back onto the institute method.
    init(_ vapor: HTTPMethod) {
        self.init(rawValue: vapor.rawValue)
    }
}
