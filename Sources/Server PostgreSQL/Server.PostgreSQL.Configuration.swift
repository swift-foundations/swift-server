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

extension Server.PostgreSQL {
    /// Connection configuration for the executor's pooled client.
    public struct Configuration: Sendable {
        public var host: String
        public var port: Int
        public var username: String
        public var password: String?
        public var database: String?
        public var security: Server.PostgreSQL.Configuration.Security

        public init(
            host: String = "localhost",
            port: Int = 5432,
            username: String,
            password: String? = nil,
            database: String? = nil,
            security: Server.PostgreSQL.Configuration.Security = .preferred
        ) {
            self.host = host
            self.port = port
            self.username = username
            self.password = password
            self.database = database
            self.security = security
        }
    }
}
