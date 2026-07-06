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

import Testing

import Server
import Server_Shared

// MARK: - Status vocabulary

// L2 delta: RFC 9110's `HTTP.Status` names these `isSuccessful`/`isRedirection` (the dissolved
// prototype spelled them `isSuccess`/`isRedirect`) — same semantics, spec-owned names.
@Test func statusSuccessAndRedirectRanges() {
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
@Test func methodRawValuesAndCases() {
    #expect(HTTP.Method.get.rawValue == "GET")
    #expect(HTTP.Method.delete.rawValue == "DELETE")
    #expect(HTTP.Method.allCases.count == 9)
}

// MARK: - Headers (case-insensitive, order-preserving)

@Test func headersLookupIsCaseInsensitive() {
    var headers = HTTP.Headers()
    headers.add(name: "Content-Type", value: "text/html")
    #expect(headers.first(name: "content-type") == "text/html")
    #expect(headers.first(name: "CONTENT-TYPE") == "text/html")
}

@Test func headersReplaceCollapsesDuplicates() {
    var headers = HTTP.Headers()
    headers.add(name: "X-Tag", value: "a")
    headers.add(name: "x-tag", value: "b")
    #expect(headers.all(name: "X-Tag") == ["a", "b"])
    headers.replace(name: "X-TAG", value: "c")
    #expect(headers.all(name: "x-tag") == ["c"])
}

// MARK: - Response building

@Test func htmlResponseSetsBodyAndContentType() {
    let response = Server.Response.html("<h1>hi</h1>")
    #expect(response.status == .ok)
    #expect(response.headers.first(name: "content-type")?.contains("text/html") == true)
    #expect(String(decoding: response.body, as: UTF8.self) == "<h1>hi</h1>")
}

@Test func jsonStringResponseSetsContentType() {
    let response = Server.Response.json(#"{"ok":true}"#)
    #expect(response.headers.first(name: "content-type")?.contains("application/json") == true)
    #expect(String(decoding: response.body, as: UTF8.self) == #"{"ok":true}"#)
}

@Test func redirectResponseUsesSeeOtherAndLocation() {
    let response = Server.Response.redirect(to: "/login")
    #expect(response.status == .seeOther)
    #expect(response.headers.first(name: "location") == "/login")
}

@Test func permanentRedirectUses301() {
    let response = Server.Response.redirect(to: "/new", permanent: true)
    #expect(response.status.code == 301)
}

@Test func bareStatusResponseHasNoBody() {
    let response = Server.Response.status(.noContent)
    #expect(response.status.code == 204)
    #expect(response.body.isEmpty)
}

// MARK: - Request

@Test func requestJoinsPathAndDecodesBody() {
    let request = Server.Request(method: .get, path: ["analytics", "user"], body: Array("data".utf8))
    #expect(request.pathString == "/analytics/user")
    #expect(request.bodyString == "data")
}

// MARK: - Environment

@Test func environmentTypedAccessors() {
    let environment = Server.Environment(
        name: "test",
        variables: ["PORT": "8080", "DEBUG": "true", "FLAG": "off", "NAME": "repotraffic"]
    )
    #expect(environment.int("PORT") == 8080)
    #expect(environment.bool("DEBUG") == true)
    #expect(environment.bool("FLAG") == false)
    #expect(environment.string("NAME") == "repotraffic")
    #expect(environment["MISSING"] == nil)
}

// MARK: - Error → status mapping

@Test func errorMapsToStatus() {
    #expect(Server.Error.notFound.status == .notFound)
    #expect(Server.Error.unauthorized.status.code == 401)
    #expect(Server.Error.badRequest("bad").status == .badRequest)
    #expect(Server.Error.payloadTooLarge.status.code == 413)
    #expect(Server.Error.internalError("x").status == .internalServerError)
}

// MARK: - Route model

@Test func routeModelCarriesMethodPathAndResponder() async throws {
    let route = Server.Route(method: .post, path: ["webhook", "stripe"]) { _ in .status(.ok) }
    #expect(route.method == .post)
    #expect(route.path == ["webhook", "stripe"])
    let response = try await route.respond(Server.Request(method: .post, path: ["webhook", "stripe"]))
    #expect(response.status == .ok)
}

// MARK: - Middleware chain

private struct TagMiddleware: Server.Middleware {
    let value: String
    func intercept(
        _ request: Server.Request,
        next: Server.Responder
    ) async throws(Server.Error) -> Server.Response {
        var response = try await next(request)
        response.headers.add(name: "X-Tag", value: value)
        return response
    }
}

@Test func middlewareChainWrapsResponderOutermostFirst() async throws {
    let base: Server.Responder = { _ in .text("hi") }
    let middleware: [any Server.Middleware] = [TagMiddleware(value: "a"), TagMiddleware(value: "b")]
    let responder = middleware.chain(around: base)
    let response = try await responder(Server.Request(method: .get, path: []))
    #expect(String(decoding: response.body, as: UTF8.self) == "hi")
    // Outermost ("a") runs last on the way out, so both tags are present, "b" added before "a".
    #expect(response.headers.all(name: "X-Tag") == ["b", "a"])
}
