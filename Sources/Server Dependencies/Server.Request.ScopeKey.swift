//
//  Server.Request.ScopeKey.swift
//  swift-server
//

public import Dependencies
public import Server

enum ServerKey: Dependency.Key {}

extension ServerKey {
    static let liveValue = Server.Request.Scope()
    static let testValue = Server.Request.Scope()
}
