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

// Foundation exception: ProcessInfo backs `.detect()` and `URL` backs the `url(_:)` accessor.
// URL is deliberately exposed on the public surface — the first consumer reads `envVars.url(...)`
// for base-URL configuration, so a Foundation-free substitute would break the call site. Every
// other accessor is stdlib-only.
public import Foundation

extension Server {
    /// Environment/configuration access: a named environment plus its variable bindings.
    ///
    /// Construct from the process environment with ``detect()`` at runtime, or from an explicit
    /// dictionary in tests. Consumers extend this type with their own typed accessors, exactly as
    /// the first consumer extends its environment type with `databaseHost`, `redisUrl`, etc.
    public struct Environment: Sendable {
        /// The environment name, e.g. `"development"` or `"production"`.
        public var name: String
        public var variables: [String: String]

        public init(name: String, variables: [String: String] = [:]) {
            self.name = name
            self.variables = variables
        }
    }
}

extension Server.Environment {
    /// Builds an environment from the current process environment. The name is taken from `ENV`
    /// (falling back to `ENVIRONMENT`, then `"development"`).
    public static func detect() -> Self {
        let variables = ProcessInfo.processInfo.environment
        let name = variables["ENV"] ?? variables["ENVIRONMENT"] ?? "development"
        return Self(name: name, variables: variables)
    }

    /// Untyped access to a variable. Consumers build typed accessors on top of this, per the
    /// first consumer's `EnvVars` extension pattern.
    public subscript(key: String) -> String? {
        get { variables[key] }
        set { variables[key] = newValue }
    }

    /// The string value for a key.
    public func string(_ key: String) -> String? { variables[key] }

    /// The integer value for a key, or `nil` when absent or unparsable.
    public func int(_ key: String) -> Int? { variables[key].flatMap(Int.init) }

    /// The boolean value for a key. `"1"`, `"true"`, `"yes"`, `"on"` (case-insensitive) are true.
    public func bool(_ key: String) -> Bool? {
        guard let raw = variables[key]?.lowercased() else { return nil }
        switch raw {
        case "1", "true", "yes", "on": return true
        case "0", "false", "no", "off": return false
        default: return nil
        }
    }

    /// The URL value for a key. (Foundation `URL` — a documented public-surface exception.)
    public func url(_ key: String) -> URL? { variables[key].flatMap { URL(string: $0) } }
}
