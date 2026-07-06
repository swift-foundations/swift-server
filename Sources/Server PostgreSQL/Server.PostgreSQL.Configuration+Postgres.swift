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

internal import NIOSSL
internal import PostgresNIO

extension Server.PostgreSQL.Configuration {
    /// The engine configuration for this institute configuration.
    var postgres: PostgresClient.Configuration {
        let tls: PostgresClient.Configuration.TLS
        switch security {
        case .disabled: tls = .disable
        case .preferred: tls = .prefer(.makeClientConfiguration())
        case .required: tls = .require(.makeClientConfiguration())
        }
        return PostgresClient.Configuration(
            host: host,
            port: port,
            username: username,
            password: password,
            database: database,
            tls: tls
        )
    }
}
