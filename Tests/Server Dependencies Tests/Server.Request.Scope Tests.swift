//
//  Server.Request.Scope Tests.swift
//  swift-server
//

import Dependencies
import HTTP_Standard
import Server
import Server_Dependencies_Integration
import Testing

extension Server.Request.Scope {
    @Suite struct Tests {}
}

extension Server.Request.Scope.Tests {
    @Test
    func `scope is empty outside a request context`() {
        @Dependency(\.server.request) var request
        #expect(request == nil)
    }

    @Test
    func `populated scope yields the request head`() {
        let head = Server.Request(
            method: .get,
            path: ["billing", "portal"],
            query: "session=abc",
            headers: .init()
        )
        withDependencies {
            $0.server.request = head
        } operation: {
            @Dependency(\.server.request) var request
            #expect(request?.method == .get)
            #expect(request?.path == ["billing", "portal"])
            #expect(request?.query == "session=abc")
            #expect(request?.body.isEmpty == true)
        }
    }
}
