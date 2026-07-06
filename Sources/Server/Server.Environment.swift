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

internal import Environment

// swift-environment's top-level `Environment` enum collides with our own nested
// `Server.Environment` inside this file — the same shape of collision `Server.Application.swift`
// documents for Vapor's `public protocol Server`. This file-private alias disambiguates the L3
// package's type from `Server.Environment` in implementation bodies.
private typealias SystemEnvironment = Environment

// L2 API gap: `Environment`'s `@_exported import Kernel` transitively re-exports a Kernel-layer
// type also named `String` (a `~Copyable` low-level primitive, distinct from `Swift.String`),
// so a bare `String` in this file is ambiguous once `Environment` is imported. `Swift.String` is
// spelled out everywhere below — the same defensive qualification `swift-environment`'s own
// source uses throughout (e.g. `Environment.Read.callAsFunction(_ name: Swift.String)`).
extension Server {
    /// Environment/configuration access: a named environment plus its variable bindings.
    ///
    /// Construct from the process environment with ``detect()`` at runtime, or from an explicit
    /// dictionary in tests. Consumers extend this type with their own typed accessors, exactly as
    /// the first consumer extends its environment type with `databaseHost`, `redisUrl`, etc.
    public struct Environment: Sendable {
        /// The environment name, e.g. `"development"` or `"production"`.
        public var name: Swift.String
        public var variables: [Swift.String: Swift.String]

        public init(name: Swift.String, variables: [Swift.String: Swift.String] = [:]) {
            self.name = name
            self.variables = variables
        }
    }
}

extension Server.Environment {
    /// Builds an environment from the current process environment (via L3 `swift-environment`,
    /// Foundation-free). The name is taken from `ENV` (falling back to `ENVIRONMENT`, then
    /// `"development"`).
    public static func detect() -> Self {
        let variables = SystemEnvironment.read.all()
        let name = variables["ENV"] ?? variables["ENVIRONMENT"] ?? "development"
        return Self(name: name, variables: variables)
    }

    /// Untyped access to a variable. Consumers build typed accessors on top of this, per the
    /// first consumer's `EnvVars` extension pattern.
    public subscript(key: Swift.String) -> Swift.String? {
        get { variables[key] }
        set { variables[key] = newValue }
    }

    /// The string value for a key.
    public func string(_ key: Swift.String) -> Swift.String? { variables[key] }

    /// The integer value for a key, or `nil` when absent or unparsable.
    public func int(_ key: Swift.String) -> Int? { variables[key].flatMap(Int.init) }

    /// The boolean value for a key. `"1"`, `"true"`, `"yes"`, `"on"` (case-insensitive) are true.
    public func bool(_ key: Swift.String) -> Bool? {
        guard let raw = variables[key]?.lowercased() else { return nil }
        switch raw {
        case "1", "true", "yes", "on": return true
        case "0", "false", "no", "off": return false
        default: return nil
        }
    }

    /// The string value for a URL-shaped key.
    ///
    /// L2 API gap: `swift-environment` is Foundation-free and carries no URL type, so this
    /// accessor returns the raw string instead of the prototype's `Foundation.URL` — no call
    /// site in this package consumed the `URL` return type, so this is a pure signature
    /// narrowing, not a behavior change. Callers parse it with whatever URL type they need.
    public func url(_ key: Swift.String) -> Swift.String? { variables[key] }
}
