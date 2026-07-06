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
    /// The configuration a `Server.Application` binds at boot.
    public struct Configuration: Sendable {
        public var hostname: String
        public var port: Int
        /// The maximum accepted request body size, in bytes. Defaults to 10 MiB, matching the
        /// first consumer's `app.routes.defaultMaxBodySize = "10mb"`.
        public var maximumBodySize: Int
        public var environment: Server.Environment

        public init(
            hostname: String = "127.0.0.1",
            port: Int = 8080,
            maximumBodySize: Int = 10 * 1024 * 1024,
            environment: Server.Environment = .detect()
        ) {
            self.hostname = hostname
            self.port = port
            self.maximumBodySize = maximumBodySize
            self.environment = environment
        }
    }
}
