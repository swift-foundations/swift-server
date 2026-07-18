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

internal import HTTP_Standard

extension HTTP.Headers {
    package init(_ literal: [String: String]) {
        self.init(
            literal.map { HTTP.Header.Field(name: .init($0.key), value: .init(unchecked: $0.value)) }
        )
    }

    package mutating func add(name: String, value: String) {
        append(HTTP.Header.Field(name: .init(name), value: .init(unchecked: value)))
    }

    package mutating func replace(name: String, value: String) {
        removeAll(named: name)
        append(HTTP.Header.Field(name: .init(name), value: .init(unchecked: value)))
    }

    package func first(name: String) -> String? {
        first(name)?.rawValue
    }

    package func all(name: String) -> [String] {
        values(name).map(\.rawValue)
    }
}
