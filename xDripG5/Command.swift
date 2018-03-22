//
//  Command.swift
//  xDripG5
//
//  Created by Paul Dickens on 22/03/2018.
//  Copyright © 2018 LoopKit Authors. All rights reserved.
//

import Foundation
import HealthKit


public enum Command: RawRepresentable {
    public typealias RawValue = [String: Any]

    case startSensor(at: Date)
    case stopSensor(at: Date)
    case calibrateSensor(to: HKQuantity, at: Date)

    private enum Action: UInt8 {
        case startSensor = 0
        case stopSensor = 1
        case calibrateSensor = 2
    }

    public init?(rawValue: RawValue) {
        guard let action = rawValue["action"] as? Action else {
            return nil
        }

        switch action {
        case .startSensor:
            guard let date = rawValue["date"] as? Date else {
                return nil
            }
            self = .startSensor(at: date)
        case .stopSensor:
            guard let date = rawValue["date"] as? Date else {
                return nil
            }
            self = .stopSensor(at: date)
        case .calibrateSensor:
            guard let date = rawValue["date"] as? Date, let glucose = rawValue["glucose"] as? HKQuantity else {
                return nil
            }
            self = .calibrateSensor(to: glucose, at: date)
        }
    }

    public var rawValue: RawValue {
        switch self {
        case .startSensor(let date):
            return [
                "action": Action.startSensor,
                "date": date
            ]
        case .stopSensor(let date):
            return [
                "action": Action.stopSensor,
                "date": date
            ]
        case .calibrateSensor(let glucose, let date):
            return [
                "action": Action.calibrateSensor,
                "date": date,
                "glucose": glucose
            ]
        }
    }
}
