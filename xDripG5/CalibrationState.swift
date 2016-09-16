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

    case stopped
    case warmup
    case needFirstInitialCalibration
    case needSecondInitialCalibration
    case ok
    case needCalibration
    case unknown(RawValue)

    init(rawValue: UInt8) {
        switch rawValue {
        case 1:
            self = .stopped
        case 2:
            self = .warmup
        case 4:
            self = .needFirstInitialCalibration
        case 5:
            self = .needSecondInitialCalibration
        case 6:
            self = .ok
        case 7:
            self = .needCalibration
        default:
            self = .unknown(rawValue)
        }
    }

    public var hasReliableGlucose: Bool {
        return self == .ok || self == .needCalibration
    }
}

extension CalibrationState: Equatable { }

public func ==(lhs: CalibrationState, rhs: CalibrationState) -> Bool {
    switch (lhs, rhs) {
    case (.stopped, .stopped), (.warmup, .warmup), (.needFirstInitialCalibration, .needFirstInitialCalibration), (.needSecondInitialCalibration, .needSecondInitialCalibration), (.ok, .ok), (.needCalibration, .needCalibration):
        return true
    case let (.unknown(lhsRaw), .unknown(rhsRaw)):
        return lhsRaw == rhsRaw
    default:
        return false
    }
}
