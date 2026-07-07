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

import Server_HTTP_Client
import Server_Shared
import Testing

// MARK: - Request building

@Test func requestDefaultsToGetWithEmptyBody() {
    let request = Server.HTTP.Request(url: "https://example.com/api")
    #expect(request.method == .get)
    #expect(request.url == "https://example.com/api")
    #expect(request.body.isEmpty)
    #expect(request.headers.isEmpty)
}

@Test func requestCarriesMethodHeadersAndBody() {
    let request = Server.HTTP.Request(
        method: .post,
        url: "https://example.com",
        headers: HTTP.Headers(["Authorization": "Bearer token"]),
        body: Array("payload".utf8)
    )
    #expect(request.method == .post)
    #expect(request.headers.first(name: "authorization") == "Bearer token")
    #expect(String(decoding: request.body, as: UTF8.self) == "payload")
}

// MARK: - JSON request convenience

private struct SamplePayload: Encodable {
    let name: String
    let count: Int
}

@Test func jsonRequestSetsBodyAndContentType() throws {
    let request = try Server.HTTP.Request.json(
        .post,
        url: "https://example.com/webhook",
        value: SamplePayload(name: "repotraffic", count: 3)
    )
    #expect(request.method == .post)
    #expect(request.headers.first(name: "content-type")?.contains("application/json") == true)
    #expect(!request.body.isEmpty)
    #expect(String(decoding: request.body, as: UTF8.self).contains("repotraffic"))
}

// MARK: - Response

@Test func responseBodyStringDecodesUTF8() {
    let response = Server.HTTP.Response(status: .ok, body: Array("hello".utf8))
    #expect(response.status == .ok)
    #expect(response.bodyString == "hello")
}

@Test func responseJSONRoundTrip() throws {
    struct Body: Codable, Equatable { let value: Int }
    let request = try Server.HTTP.Request.json(.post, url: "https://x", value: Body(value: 42))
    let response = Server.HTTP.Response(status: .ok, body: request.body)
    let decoded: Body = try response.json()
    #expect(decoded == Body(value: 42))
}
