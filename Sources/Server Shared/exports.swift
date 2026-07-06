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

// The institute L2 HTTP vocabulary (RFC 9110/9111/9112, converged by `swift-http-standard`)
// replaces the vocabulary this target used to re-declare (`Server.Method`, `Server.Status`,
// `Server.Headers`, `Server.Headers.Field`) — institute-server-stack-architecture.md Q1.
// `@_exported` makes `HTTP.Method` / `HTTP.Status` / `HTTP.Headers` / `HTTP.Header.Field`
// appear on every consumer that imports `Server Shared`, matching the ergonomics of the
// dissolved local types without re-declaring them.
@_exported public import HTTP_Standard
