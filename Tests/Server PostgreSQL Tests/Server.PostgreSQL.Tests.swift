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

import SQL
import Server_PostgreSQL
import Server_Shared
import Testing
import Time_Primitive

// The statement seam (`SQL.Query` carrying sql + bindings), the binding vocabulary
// (`SQL.Value`), and the migrator now live in the L3 `swift-sql` / `swift-migrations` packages and
// are covered by their own suites. What THIS target owns and can cover engine-free is the
// connection configuration and the `Date` → `Instant` interval conversion the Live row performs.

// MARK: - Configuration

@Test func `Configuration applies localhost defaults`() {
    let configuration = Server.PostgreSQL.Configuration(username: "postgres")
    #expect(configuration.host == "localhost")
    #expect(configuration.port == 5432)
    #expect(configuration.security == .preferred)
}

@Test func `Configuration carries explicit overrides`() {
    let configuration = Server.PostgreSQL.Configuration(
        host: "db.internal",
        port: 6000,
        username: "app",
        password: "secret",
        database: "repotraffic",
        security: .required
    )
    #expect(configuration.host == "db.internal")
    #expect(configuration.port == 6000)
    #expect(configuration.database == "repotraffic")
    #expect(configuration.security == .required)
}

// MARK: - Date → Instant interval conversion (the Live row's timestamp seam, engine-free)

@Test func `Instant from a whole-second interval has zero fraction`() {
    let instant = Server.PostgreSQL.Row.instant(fromUnixInterval: 1_732_276_800)
    #expect(instant.secondsSinceUnixEpoch == 1_732_276_800)
    #expect(instant.nanosecondFraction == 0)
}

@Test func `Instant from a positive sub-second interval keeps the fraction`() {
    let instant = Server.PostgreSQL.Row.instant(fromUnixInterval: 1.5)
    #expect(instant.secondsSinceUnixEpoch == 1)
    #expect(instant.nanosecondFraction == 500_000_000)
}

@Test func `Instant from a pre-1970 interval floors to a non-negative fraction`() {
    // -0.5s before the epoch must floor to (-1s, +0.5s) so the fraction is non-negative.
    let instant = Server.PostgreSQL.Row.instant(fromUnixInterval: -0.5)
    #expect(instant.secondsSinceUnixEpoch == -1)
    #expect(instant.nanosecondFraction == 500_000_000)
    #expect(instant.nanosecondFraction >= 0)
    #expect(instant.nanosecondFraction < 1_000_000_000)
}

@Test func `Instant from a negative whole-second interval has zero fraction`() {
    let instant = Server.PostgreSQL.Row.instant(fromUnixInterval: -2)
    #expect(instant.secondsSinceUnixEpoch == -2)
    #expect(instant.nanosecondFraction == 0)
}

@Test func `Instant rounding a near-full-second fraction carries into the seconds`() {
    // A fraction that rounds up to a full second must carry into the seconds and reset the fraction.
    let instant = Server.PostgreSQL.Row.instant(fromUnixInterval: 0.9999999996)
    #expect(instant.secondsSinceUnixEpoch == 1)
    #expect(instant.nanosecondFraction == 0)
}
