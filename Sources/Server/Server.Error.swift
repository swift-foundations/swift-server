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

public import Server_Shared

extension Server {
    /// The typed error domain thrown by every operation on the core transport surface.
    ///
    /// Each case maps to an HTTP status (``Server/Error/status``) so a handler can translate the
    /// error domain into a response uniformly — mirroring the consumer's
    /// `catch AbortError where status == .unauthorized` pattern without an engine's error type
    /// leaking through the membrane.
    public enum Error: Swift.Error, Sendable {
        /// The requested resource does not exist (404).
        case notFound
        /// The request was malformed; the string describes what (400).
        case badRequest(String)
        /// Authentication is required or failed (401).
        case unauthorized
        /// The caller is authenticated but not permitted (403).
        case forbidden
        /// The request body exceeded the configured maximum (413).
        case payloadTooLarge
        /// A value could not be decoded from the request; the string names the value (422).
        case decoding(String)
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
    public var status: Server.Status {
        switch self {
        case .notFound: .notFound
        case .badRequest: .badRequest
        case .unauthorized: .unauthorized
        case .forbidden: .forbidden
        case .payloadTooLarge: .init(code: 413, reason: "Payload Too Large")
        case .decoding: .unprocessableEntity
        case .encoding: .internalServerError
        case .engine: .internalServerError
        case .unavailable: .serviceUnavailable
        case .internalError: .internalServerError
        }
    }

    /// A human-readable description of the failure condition.
    public var message: String {
        switch self {
        case .notFound: "Not found"
        case .badRequest(let reason): "Bad request: \(reason)"
        case .unauthorized: "Unauthorized"
        case .forbidden: "Forbidden"
        case .payloadTooLarge: "Payload too large"
        case .decoding(let value): "Failed to decode \(value)"
        case .encoding(let value): "Failed to encode \(value)"
        case .engine(let description): "Engine error: \(description)"
        case .unavailable(let service): "Unavailable: \(service)"
        case .internalError(let description): "Internal error: \(description)"
        }
    }
}
