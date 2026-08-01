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

extension Server.Jobs {
    final class Installer: Scheduler.Installing {
        var jobs: [String: @Sendable (Any) async -> Result<Void, Scheduler.Error>] = [:]
        var scheduled: [String: @Sendable () async -> Result<Void, Scheduler.Error>] = [:]
    }
}

extension Server.Jobs.Installer {
    func install<J: Scheduler.Job>(_ job: J) {
        let handler: @Sendable (Any) async -> Result<Void, Scheduler.Error> = { payload in
            guard let payload = payload as? J.Payload else {
                return .failure(.dispatch("invalid payload for \(J.name)"))
            }
            do {
                try await job.run(payload)
                return .success(())
            } catch {
                return .failure(.run("\(error)"))
            }
        }
        jobs[J.name] = handler
    }

    func install<S: Scheduler.Scheduled>(_ scheduled: S) {
        let handler: @Sendable () async -> Result<Void, Scheduler.Error> = {
            do {
                try await scheduled.run()
                return .success(())
            } catch {
                return .failure(.run("\(error)"))
            }
        }
        self.scheduled[S.name] = handler
    }
}
