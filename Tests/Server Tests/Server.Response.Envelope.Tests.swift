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

import Foundation
import Server
import HTTP_Standard
import Testing

// A wire-shaped decoder mirroring the `{ success, data, message, timestamp }` envelope, used to
// assert the serialized body rather than reaching into the internal `Server.Response.Envelope`.
private struct DecodedEnvelope<Payload: Decodable>: Decodable {
    let success: Bool
    let data: Payload?
    let message: String?
    let timestamp: String
}

private struct Payload: Codable, Equatable {
    let id: Int
    let name: String
}

@Test func `json envelope carries success data message and timestamp`() throws {
    let response = try Server.Response.json(
        success: true,
        data: Payload(id: 7, name: "repotraffic"),
        message: "created"
    )
    #expect(response.status == .ok)
    #expect(response.headers.first(name: "content-type")?.contains("application/json") == true)

    let decoded = try JSONDecoder().decode(DecodedEnvelope<Payload>.self, from: Data(response.body))
    #expect(decoded.success == true)
    #expect(decoded.data == Payload(id: 7, name: "repotraffic"))
    #expect(decoded.message == "created")
    #expect(!decoded.timestamp.isEmpty)
}

@Test func `json envelope honors an explicit status`() throws {
    let response = try Server.Response.json(
        success: false,
        data: Payload(id: 1, name: "x"),
        message: "boom",
        status: .internalServerError
    )
    #expect(response.status == .internalServerError)
    #expect(response.status.code == 500)
}

@Test func `no-data json envelope omits a payload`() throws {
    let response = try Server.Response.json(success: false, message: "not found", status: .notFound)
    #expect(response.status == .notFound)

    let decoded = try JSONDecoder().decode(DecodedEnvelope<Payload>.self, from: Data(response.body))
    #expect(decoded.success == false)
    #expect(decoded.data == nil)
    #expect(decoded.message == "not found")
    #expect(!decoded.timestamp.isEmpty)
}

@Test func `no-data json envelope defaults message to nil and status to ok`() throws {
    let response = try Server.Response.json(success: true)
    #expect(response.status == .ok)

    let decoded = try JSONDecoder().decode(DecodedEnvelope<Payload>.self, from: Data(response.body))
    #expect(decoded.success == true)
    #expect(decoded.data == nil)
    #expect(decoded.message == nil)
}
