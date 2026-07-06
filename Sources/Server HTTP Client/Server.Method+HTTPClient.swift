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

internal import NIOHTTP1
internal import Server_Shared

// `HTTP.Method` (RFC 9110, open method set) and `NIOHTTP1.HTTPMethod` (`RawRepresentable` with a
// `.RAW(value:)` catch-all case) are both String-keyed open sets, so the bridge is a lossless
// rawValue round-trip — no default fallback needed, unlike the dissolved prototype's closed
// 7-case enum.
extension HTTP.Method {
    /// The engine method for this institute method.
    var http: HTTPMethod {
        HTTPMethod(rawValue: rawValue)
    }
}
