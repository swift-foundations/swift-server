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

public import HTTP_Standard

extension Server {
    /// The typed error domain thrown by every operation on the core transport surface.
    ///
    /// Each case maps to an HTTP status (``Server/Error/status``) so a handler can translate the
    /// error domain into a response uniformly — mirroring the consumer's
    /// `catch AbortError where status == .unauthorized` pattern without an engine's error type
    /// leaking through the membrane.
    public enum Error: Swift.Error, Sendable {
        /// The requested resource does not exist; the string preserves the supplied reason (404).
        case notFound(String)
        /// The request was malformed; the string describes what (400).
        case badRequest(String)
        /// Authentication is required or failed (401).
        case unauthorized
        /// Payment is required to access the resource; the string preserves the supplied reason (402).
        case paymentRequired(String)
        /// The caller is authenticated but not permitted; the string preserves the supplied reason (403).
        case forbidden(String)
        /// The request body exceeded the configured maximum (413).
        case payloadTooLarge
        /// A value could not be decoded from the request; the string names the value (422).
        case decoding(String)
        /// The requested operation is not implemented; the string preserves the supplied reason (501).
        case notImplemented(String)
        /// A value could not be encoded into the response; the string names the value (500).
        case encoding(String)
        /// The wrapped engine failed; the string carries the engine's description (500).
        case engine(String)
        /// A downstream service is unavailable; the string describes it (503).
        case unavailable(String)
        /// An unclassified internal failure; the string describes it (500).
        case internalError(String)
    }
}

extension Server.Error {
    /// The HTTP status this error maps to.
    ///
    /// L2 delta: RFC 9110 renamed 413 from "Payload Too Large" to "Content Too Large"
    /// (`.contentTooLarge`) and 422 from "Unprocessable Entity" to "Unprocessable Content"
    /// (`.unprocessableContent`) — the dissolved prototype's hand-rolled presets used the
    /// obsoleted reason phrases; this adopts the spec-current ones (same codes).
    public var status: HTTP.Status {
        switch self {
        case .notFound: .notFound
        case .badRequest: .badRequest
        case .unauthorized: .unauthorized
        case .paymentRequired: .paymentRequired
        case .forbidden: .forbidden
        case .payloadTooLarge: .contentTooLarge
        case .decoding: .unprocessableContent
        case .notImplemented: .notImplemented
        case .encoding: .internalServerError
        case .engine: .internalServerError
        case .unavailable: .serviceUnavailable
        case .internalError: .internalServerError
        }
    }

    /// A human-readable description of the failure condition.
    public var message: String {
        switch self {
        case .notFound(let reason): reason
        case .badRequest(let reason): "Bad request: \(reason)"
        case .unauthorized: "Unauthorized"
        case .paymentRequired(let reason): reason
        case .forbidden(let reason): reason
        case .payloadTooLarge: "Payload too large"
        case .decoding(let value): "Failed to decode \(value)"
        case .notImplemented(let reason): reason
        case .encoding(let value): "Failed to encode \(value)"
        case .engine(let description): "Engine error: \(description)"
        case .unavailable(let service): "Unavailable: \(service)"
        case .internalError(let description): "Internal error: \(description)"
        }
    }
}
