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

public import HTML_Rendering_Core
public import Server

extension Server.Response {
    /// Renders a complete HTML document into an engine-free response.
    public static func html(
        _ document: some HTML.Document.`Protocol`,
        configuration: HTML.Context.Configuration? = nil
    ) throws(HTML.Context.Configuration.Error) -> Self {
        try html(String(document, configuration: configuration))
    }
}
