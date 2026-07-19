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

import Server
import HTTP_Standard
import Testing

// MARK: - Status vocabulary

// L2 delta: RFC 9110's `HTTP.Status` names these `isSuccessful`/`isRedirection` (the dissolved
// prototype spelled them `isSuccess`/`isRedirect`) — same semantics, spec-owned names.
@Test func `status Success And Redirect Ranges`() {
    #expect(HTTP.Status.ok.isSuccessful)
    #expect(HTTP.Status.created.isSuccessful)
    #expect(HTTP.Status.seeOther.isRedirection)
    #expect(!HTTP.Status.notFound.isSuccessful)
    #expect(HTTP.Status.noContent.code == 204)
}

// MARK: - Method

// L2 delta: `HTTP.Method` is an open method set (RawRepresentable, not a closed enum) and its
// `CaseIterable.allCases` enumerates the 9 RFC 9110 §9.3 + RFC 5789 standard methods (the
// dissolved prototype's closed enum modeled only 7 — no CONNECT/TRACE).
@Test func `method Raw Values And Cases`() {
    #expect(HTTP.Method.get.rawValue == "GET")
    #expect(HTTP.Method.delete.rawValue == "DELETE")
    #expect(HTTP.Method.allCases.count == 9)
}

// MARK: - Headers (case-insensitive, order-preserving)

@Test func `headers Lookup Is Case Insensitive`() {
    var headers = HTTP.Headers()
    headers.add(name: "Content-Type", value: "text/html")
    #expect(headers.first(name: "content-type") == "text/html")
    #expect(headers.first(name: "CONTENT-TYPE") == "text/html")
}

@Test func `headers Replace Collapses Duplicates`() {
    var headers = HTTP.Headers()
    headers.add(name: "X-Tag", value: "a")
    headers.add(name: "x-tag", value: "b")
    #expect(headers.all(name: "X-Tag") == ["a", "b"])
    headers.replace(name: "X-TAG", value: "c")
    #expect(headers.all(name: "x-tag") == ["c"])
}

// MARK: - Response building

@Test func `html Response Sets Body And Content Type`() {
    let response = Server.Response.html("<h1>hi</h1>")
    #expect(response.status == .ok)
    #expect(response.headers.first(name: "content-type")?.contains("text/html") == true)
    #expect(String(decoding: response.body, as: UTF8.self) == "<h1>hi</h1>")
}

@Test func `json String Response Sets Content Type`() {
    let response = Server.Response.json(#"{"ok":true}"#)
    #expect(response.headers.first(name: "content-type")?.contains("application/json") == true)
    #expect(String(decoding: response.body, as: UTF8.self) == #"{"ok":true}"#)
}

@Test func `redirect Response Uses See Other And Location`() {
    let response = Server.Response.redirect(to: "/login")
    #expect(response.status == .seeOther)
    #expect(response.headers.first(name: "location") == "/login")
}

@Test func `permanent Redirect Uses301`() {
    let response = Server.Response.redirect(to: "/new", permanent: true)
    #expect(response.status.code == 301)
}

@Test func `bare Status Response Has No Body`() {
    let response = Server.Response.status(.noContent)
    #expect(response.status.code == 204)
    #expect(response.body.isEmpty)
}

// MARK: - Request

@Test func `request Joins Path And Decodes Body`() {
    let request = Server.Request(method: .get, path: ["analytics", "user"], body: Array("data".utf8))
    #expect(request.pathString == "/analytics/user")
    #expect(request.bodyString == "data")
}

// MARK: - Environment

// MARK: - Error → status mapping

@Test func `error Maps To Status`() {
    #expect(Server.Error.notFound.status == .notFound)
    #expect(Server.Error.unauthorized.status.code == 401)
    #expect(Server.Error.badRequest("bad").status == .badRequest)
    #expect(Server.Error.payloadTooLarge.status.code == 413)
    #expect(Server.Error.internalError("x").status == .internalServerError)
}

@Test func `not Implemented Preserves Reason And Maps To501`() {
    let reason = "route /history is not implemented\n🙂"
    let error = Server.Error.notImplemented(reason)

    guard case .notImplemented(let payload) = error else {
        Issue.record("Expected Server.Error.notImplemented")
        return
    }

    #expect(payload == reason)
    #expect(error.message == reason)
    #expect(error.status == .notImplemented)
    #expect(error.status.code == 501)
}

// MARK: - Route model

@Test func `route Model Carries Method Path And Responder`() async throws {
    let route = Server.Route(method: .post, path: ["webhook", "stripe"]) { _ in .status(.ok) }
    #expect(route.method == .post)
    #expect(route.path == ["webhook", "stripe"])
    let response = try await route.respond(Server.Request(method: .post, path: ["webhook", "stripe"]))
    #expect(response.status == .ok)
}

// MARK: - Middleware chain

private struct TagMiddleware: Server.Middleware {
    let value: String
}

extension TagMiddleware {
    func intercept(
        _ request: Server.Request,
        next: Server.Responder
    ) async throws(Server.Error) -> Server.Response {
        var response = try await next(request)
        response.headers.add(name: "X-Tag", value: value)
        return response
    }
}

@Test func `middleware Chain Wraps Responder Outermost First`() async throws {
    let base: Server.Responder = { _ in .text("hi") }
    let middleware: [any Server.Middleware] = [TagMiddleware(value: "a"), TagMiddleware(value: "b")]
    let responder = middleware.chain(around: base)
    let response = try await responder(Server.Request(method: .get, path: []))
    #expect(String(decoding: response.body, as: UTF8.self) == "hi")
    // Outermost ("a") runs last on the way out, so both tags are present, "b" added before "a".
    #expect(response.headers.all(name: "X-Tag") == ["b", "a"])
}
