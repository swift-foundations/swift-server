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

import Foundation
import Testing

import Server_PostgreSQL
import Server_Shared

// MARK: - Statement seam

@Test func queryCarriesSQLAndBindings() {
    let query = Server.PostgreSQL.Query(
        sql: "SELECT * FROM t WHERE id = $1 AND name = $2",
        bindings: [.uuid(UUID()), .text("repotraffic")]
    )
    #expect(query.sql.contains("$1"))
    #expect(query.bindings.count == 2)
    #expect(query.bindings.last == .text("repotraffic"))
}

@Test func valueEquatable() {
    #expect(Server.PostgreSQL.Value.int(1) == .int(1))
    #expect(Server.PostgreSQL.Value.null == .null)
    #expect(Server.PostgreSQL.Value.text("a") != .text("b"))
}

// MARK: - Configuration

@Test func configurationDefaults() {
    let configuration = Server.PostgreSQL.Configuration(username: "postgres")
    #expect(configuration.host == "localhost")
    #expect(configuration.port == 5432)
    #expect(configuration.security == .preferred)
}

// MARK: - Migrator ordering (pure — no database)

@Test func migratorPreservesRegistrationOrder() {
    var migrator = Server.PostgreSQL.Migrator()
    migrator.register("v1_accounts") { _ in }
    migrator.register("v2_repositories") { _ in }
    migrator.register("v3_traffic") { _ in }
    #expect(migrator.names == ["v1_accounts", "v2_repositories", "v3_traffic"])
}

@Test func migratorPendingExcludesAppliedPreservingOrder() {
    var migrator = Server.PostgreSQL.Migrator()
    migrator.register("a") { _ in }
    migrator.register("b") { _ in }
    migrator.register("c") { _ in }
    migrator.register("d") { _ in }
    let pending = migrator.pending(applied: ["a", "c"])
    #expect(pending.map(\.name) == ["b", "d"])
}

@Test func migratorPendingEmptyWhenAllApplied() {
    var migrator = Server.PostgreSQL.Migrator()
    migrator.register("a") { _ in }
    migrator.register("b") { _ in }
    let pending = migrator.pending(applied: ["a", "b"])
    #expect(pending.isEmpty)
}

@Test func migratorAppliedTableNameIsStable() {
    #expect(Server.PostgreSQL.Migrator.appliedTableName == "_server_migrations")
}
