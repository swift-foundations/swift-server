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

// L2 API gap (institute-server-stack-architecture.md Q1/Q4): `HTTP.Headers` (RFC 9110 §6.3)
// exposes `first(_:)` / `values(_:)` typed over `Header.Field.Value`, `append(_:)` /
// `removeAll(named:)`, and a read-only `subscript(_:) -> [Header.Field.Value]?` — but no
// dictionary-literal construction, no collapse-then-set "replace", and no plain-`String`-typed
// accessors — conveniences the dissolved `Server.Headers` prototype carried. Rather than adding a
// public (and possibly retroactive-conformance-colliding) extension to the L2 type, this file
// adds `package`-scoped members: visible to every target in this package (via Swift's package
// access control, SE-0386) but invisible to `HTTP Standard`'s own consumers elsewhere.
//
// Every value constructed here comes from call sites holding static string literals (header
// names/values the membrane itself writes — "Content-Type", "Location", …) or engine-supplied
// values the wire has already validated, so the `unchecked` (non-validating) `Header.Field.Value`
// initializer is used throughout; this mirrors the dissolved prototype, which performed no
// field-value validation either.

extension HTTP.Headers {
    /// Builds headers from literal name/value pairs — the chassis-owned replacement for the
    /// dissolved `Server.Headers: ExpressibleByDictionaryLiteral` conformance. Every call site is
    /// a single-entry literal (`["Content-Type": "…"]`), so dictionary key ordering never matters
    /// in practice.
    package init(_ literal: [String: String]) {
        self.init(
            literal.map { HTTP.Header.Field(name: .init($0.key), value: .init(unchecked: $0.value)) }
        )
    }

    /// Appends a field without removing any existing field of the same name — the chassis-owned
    /// replacement for the dissolved `Server.Headers.add(name:value:)`.
    package mutating func add(name: String, value: String) {
        append(HTTP.Header.Field(name: .init(name), value: .init(unchecked: value)))
    }

    /// Removes every field with the given name (case-insensitive) and appends a single new one —
    /// the chassis-owned replacement for the dissolved `Server.Headers.replace(name:value:)`.
    package mutating func replace(name: String, value: String) {
        removeAll(named: name)
        append(HTTP.Header.Field(name: .init(name), value: .init(unchecked: value)))
    }

    /// Gets the first value for a header field name as a plain string — the chassis-owned
    /// replacement for the dissolved `Server.Headers.first(name:)`. (The L2 type's own
    /// `first(_:)` returns `Header.Field.Value?`.)
    package func first(name: String) -> String? {
        first(name)?.rawValue
    }

    /// Gets all values for a header field name as plain strings — the chassis-owned replacement
    /// for the dissolved `Server.Headers.all(name:)`. (The L2 type's own `values(_:)` returns
    /// `[Header.Field.Value]`.)
    package func all(name: String) -> [String] {
        values(name).map(\.rawValue)
    }
}
