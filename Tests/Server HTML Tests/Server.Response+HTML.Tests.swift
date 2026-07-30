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

import HTML_Rendering_Core
private import HTTP_Standard
import Server
import Server_HTML
import Testing

@Test func `document HTML response preserves bytes headers and status`() throws {
    let document = HTML.Document {
        HTML.Text("Body")
    } head: {
        HTML.Text("Head")
    }

    let response = try Server.Response.html(document)

    #expect(response.status.code == 200)
    #expect(
        response.headers
            .filter { $0.name.rawValue.lowercased() == "content-type" }
            .map { $0.value.rawValue }
            == ["text/html; charset=utf-8"]
    )
    #expect(
        response.body
            == Array("<!doctype html><html><head>Head</head><body>Body</body></html>".utf8)
    )
}

@Test func `document HTML response propagates rendering configuration`() throws {
    let document = HTML.Document {
        HTML.Text("Body")
    } head: {
        HTML.Text("Head")
    }

    let response = try Server.Response.html(document, configuration: .pretty)

    #expect(
        response.body
            == Array(
                """
                <!doctype html>
                <html>
                  <head>Head
                  </head>
                  <body>Body
                  </body>
                </html>
                """.utf8
            )
    )
}

@Test func `document HTML response exposes its typed rendering failure`() throws {
    let render:
        (
            HTML.Document<HTML.Text, HTML.Text>,
            HTML.Context.Configuration?
        ) throws(HTML.Context.Configuration.Error) -> Server.Response = Server.Response.html
    let document = HTML.Document {
        HTML.Text("Body")
    } head: {
        HTML.Text("Head")
    }

    let response = try render(document, nil)

    #expect(response.status.code == 200)
}
