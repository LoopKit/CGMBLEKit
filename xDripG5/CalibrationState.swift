//
//  CalibrationState.swift
//  xDripG5
//
//  Created by Nate Racklyeft on 8/6/16.
//  Copyright © 2016 Nathan Racklyeft. All rights reserved.
//

import Foundation


public enum CalibrationState {
    public typealias RawValue = UInt8

    case Stopped
    case Warmup
    case NeedFirstInitialCalibration
    case NeedSecondInitialCalibration
    case OK
    case NeedCalibration
    case Unknown(RawValue)

    init(rawValue: UInt8) {
        switch rawValue {
        case 1:
            self = .Stopped
        case 2:
            self = .Warmup
        case 4:
            self = .NeedFirstInitialCalibration
        case 5:
            self = .NeedSecondInitialCalibration
        case 6:
            self = .OK
        case 7:
            self = .NeedCalibration
        default:
            self = .Unknown(rawValue)
        }
    }

    public var hasReliableGlucose: Bool {
        return self == .OK || self == .NeedCalibration
    }
}

extension CalibrationState: Equatable { }

public func ==(lhs: CalibrationState, rhs: CalibrationState) -> Bool {
    switch (lhs, rhs) {
    case (.Stopped, .Stopped), (.Warmup, .Warmup), (.NeedFirstInitialCalibration, .NeedFirstInitialCalibration), (.NeedSecondInitialCalibration, .NeedSecondInitialCalibration), (.OK, .OK), (.NeedCalibration, .NeedCalibration):
        return true
    case let (.Unknown(lhsRaw), .Unknown(rhsRaw)):
        return lhsRaw == rhsRaw
    default:
        return false
    }
}
