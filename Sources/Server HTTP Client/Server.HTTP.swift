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
    /// The outbound-HTTP membrane: a thin async client over async-http-client, enough for the
    /// vendor-API `Live` targets (GitHub, Stripe, Mailgun) to migrate onto in a later version.
    public enum HTTP {}
}
