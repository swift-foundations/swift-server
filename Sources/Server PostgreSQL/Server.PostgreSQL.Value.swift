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

// Foundation exception: `UUID` and `Date` are the natural bind types for `uuid` and `timestamptz`
// columns, and PostgresNIO already encodes them. Exposing them keeps parameter binding ergonomic
// at the call site; every other case is stdlib-only.
public import Foundation

extension Server.PostgreSQL {
    /// A value bound to a statement parameter.
    ///
    /// This is the DSL-free binding vocabulary of the ``Server/PostgreSQL/Statement`` seam. It
    /// mirrors the subset of the Structured Queries `QueryBinding` cases the first consumer
    /// exercises, so a bridge from that DSL is a straight case-to-case map — but the seam carries
    /// no dependency on it.
    public enum Value: Sendable, Hashable {
        case text(String)
        case int(Int)
        case int64(Int64)
        case double(Double)
        case bool(Bool)
        case uuid(UUID)
        case timestamp(Date)
        case null
    }
}
