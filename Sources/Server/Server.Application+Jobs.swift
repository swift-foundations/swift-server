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

public import Scheduler

extension Server.Application {
    /// Registers pure Scheduler jobs on this application.
    public func register(_ registry: Scheduler.Registry) {
        let installer = Server.Jobs.Installer()
        registry.install(into: installer)
        jobInstaller = installer
    }

    /// Dispatches a registered job directly through the pure Scheduler seam.
    public func dispatch<J: Scheduler.Job>(
        _ jobType: J.Type,
        _ payload: J.Payload
    ) async throws(Scheduler.Error) {
        guard let jobInstaller, let job = jobInstaller.jobs[J.name] else {
            throw Scheduler.Error.dispatch("job is not registered: \(J.name)")
        }
        switch await job(payload) {
        case .success:
            return

        case .failure(let error):
            throw error
        }
    }
}
