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

public import Environment

extension Server {
    /// The configuration a `Server.Application` binds at boot.
    public struct Configuration: Sendable {
        public var hostname: Swift.String
        public var port: Int
        /// The maximum accepted request body size, in bytes. Defaults to 10 MiB, matching the
        /// first consumer's `app.routes.defaultMaxBodySize = "10mb"`.
        public var maximumBodySize: Int
        public var environment: Environment.Snapshot

        public init(
            hostname: Swift.String = "127.0.0.1",
            port: Int = 8080,
            maximumBodySize: Int = 10 * 1024 * 1024,
            environment: Environment.Snapshot = .effective()
        ) {
            self.hostname = hostname
            self.port = port
            self.maximumBodySize = maximumBodySize
            self.environment = environment
        }
    }
}
