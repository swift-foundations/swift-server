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

private import HTTP_Standard
import JSON
import Server
import Server_JSON
import Testing

@Test func `request JSON decodes serializable body`() throws {
    let request = Server.Request(
        method: .post,
        path: ["values"],
        body: Array(#"{"answer":42}"#.utf8)
    )

    let value = try request.json(as: [String: Int].self)

    #expect(value == ["answer": 42])
}

@Test func `request JSON normalizes decoding errors`() {
    let request = Server.Request(
        method: .post,
        path: ["values"],
        body: Array(#"{"#.utf8)
    )

    do {
        let _: String = try request.json()
        Issue.record("Expected malformed JSON to fail")
    } catch {
        switch error {
        case .decoding(let type):
            #expect(type == "String")

        default:
            Issue.record("Expected Server.Error.decoding, got \(error)")
        }
    }
}
