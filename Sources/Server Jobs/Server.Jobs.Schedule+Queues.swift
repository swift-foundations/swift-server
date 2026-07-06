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

internal import Server_Shared

internal import Queues

private typealias Server = Server_Shared.Server

extension Server.Jobs.Schedule {
    /// Applies this cadence onto the engine's schedule builder.
    func apply(to builder: ScheduleBuilder) {
        switch self {
        case .hourly(let minute):
            builder.hourly().at(ScheduleBuilder.Minute(integerLiteral: minute))
        case .daily(let hour, let minute):
            builder.daily().at(
                ScheduleBuilder.Hour24(integerLiteral: hour),
                ScheduleBuilder.Minute(integerLiteral: minute)
            )
        }
    }
}
