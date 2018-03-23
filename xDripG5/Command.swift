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

    public init?(rawValue: RawValue) {
        guard let action = rawValue["action"] as? Int else {
            return nil
        }

        switch Action(rawValue: action) {
        case .startSensor?:
            guard let date = rawValue["date"] as? Date else {
                return nil
            }
            self = .startSensor(at: date)
        case .stopSensor?:
            guard let date = rawValue["date"] as? Date else {
                return nil
            }
            self = .stopSensor(at: date)
        case .calibrateSensor?:
            guard let date = rawValue["date"] as? Date, let glucose = rawValue["glucose"] as? HKQuantity else {
                return nil
            }
            self = .calibrateSensor(to: glucose, at: date)
        case .none:
            return nil
        }
    }

    private enum Action: Int {
        case startSensor, stopSensor, calibrateSensor
    }

    public var rawValue: RawValue {
        switch self {
        case .startSensor(let date):
            return [
                "action": Action.startSensor.rawValue,
                "date": date
            ]
        case .stopSensor(let date):
            return [
                "action": Action.stopSensor.rawValue,
                "date": date
            ]
        case .calibrateSensor(let glucose, let date):
            return [
                "action": Action.calibrateSensor.rawValue,
                "date": date,
                "glucose": glucose
            ]
        }
    }
}
