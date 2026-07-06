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

/// The root namespace for the Swift Institute server-runtime membrane.
///
/// `Server` is the single seam through which the ecosystem is allowed to reach an
/// external server stack. Every engine (Vapor, PostgresNIO, vapor/queues,
/// AsyncHTTPClient) is imported *internally* by one of the satellite modules and never
/// surfaces through this namespace. Consumers see only `Server.*` value types with
/// typed throws.
public enum Server {}
