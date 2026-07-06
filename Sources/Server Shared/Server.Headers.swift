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

extension Server {
    /// An ordered collection of HTTP header fields with case-insensitive lookup.
    ///
    /// Order is preserved (some headers, e.g. `Set-Cookie`, are order-significant) and a name
    /// may repeat. Lookups compare names case-insensitively per RFC 9110.
    public struct Headers: Sendable, Hashable {
        public var fields: [Server.Headers.Field]

        public init(_ fields: [Server.Headers.Field] = []) {
            self.fields = fields
        }
    }
}

extension Server.Headers: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, String)...) {
        self.init(elements.map { Server.Headers.Field(name: $0.0, value: $0.1) })
    }
}

extension Server.Headers {
    /// A Boolean value indicating whether there are no fields.
    public var isEmpty: Bool { fields.isEmpty }

    /// The first value for a header name, compared case-insensitively (stdlib `lowercased()` —
    /// Foundation-free so this primitive stays importable by every satellite).
    public func first(name: String) -> String? {
        let target = name.lowercased()
        return fields.first { $0.name.lowercased() == target }?.value
    }

    /// All values for a header name, compared case-insensitively.
    public func all(name: String) -> [String] {
        let target = name.lowercased()
        return fields
            .filter { $0.name.lowercased() == target }
            .map(\.value)
    }

    /// Appends a header field without removing any existing field of the same name.
    public mutating func add(name: String, value: String) {
        fields.append(Server.Headers.Field(name: name, value: value))
    }

    /// Removes every field with the given name (case-insensitive) and appends a single new one.
    public mutating func replace(name: String, value: String) {
        let target = name.lowercased()
        fields.removeAll { $0.name.lowercased() == target }
        fields.append(Server.Headers.Field(name: name, value: value))
    }

    /// Case-insensitive subscript over the first value for a name.
    public subscript(name: String) -> String? {
        get { first(name: name) }
        set {
            if let newValue {
                replace(name: name, value: newValue)
            } else {
                let target = name.lowercased()
                fields.removeAll { $0.name.lowercased() == target }
            }
        }
    }
}
