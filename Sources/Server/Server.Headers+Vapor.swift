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
internal import Vapor

extension HTTP.Headers {
    /// The engine headers for these institute headers.
    var vapor: HTTPHeaders {
        var headers = HTTPHeaders()
        for field in self {
            headers.add(name: field.name.rawValue, value: field.value.rawValue)
        }
        return headers
    }

    /// Maps engine headers onto institute headers, preserving order and duplicates.
    init(_ vapor: HTTPHeaders) {
        self.init(
            vapor.map { HTTP.Header.Field(name: .init($0.name), value: .init(unchecked: $0.value)) }
        )
    }
}
