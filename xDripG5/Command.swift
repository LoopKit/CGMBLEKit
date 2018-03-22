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
    case startSensor(at: Date)
    case stopSensor(at: Date)
    case calibrateSensor(to: HKQuantity, at: Date)

    public typealias RawValue = [String: Any]

    public init?(rawValue: RawValue) {
        guard let command = rawValue["command"] as? Int else {
            return nil
        }

        switch command {
        case 0:
            guard let date = rawValue["date"] as? Date else {
                return nil
            }
            self = .startSensor(at: date)
        case 1:
            guard let date = rawValue["date"] as? Date else {
                return nil
            }
            self = .stopSensor(at: date)
        case 2:
            guard let date = rawValue["date"] as? Date, let glucose = rawValue["glucose"] as? HKQuantity else {
                return nil
            }
            self = .calibrateSensor(to: glucose, at: date)
        default:
            return nil
        }
    }

    public var rawValue: RawValue {
        switch self {
        case .startSensor(let date):
            return [
                "command": 0,
                "date": date
            ]
        case .stopSensor(let date):
            return [
                "command": 1,
                "date": date
            ]
        case .calibrateSensor(let glucose, let date):
            return [
                "command": 2,
                "date": date,
                "glucose": glucose
            ]
        }
    }
}
