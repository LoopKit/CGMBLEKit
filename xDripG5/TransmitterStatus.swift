//
//  TransmitterStatus.swift
//  xDripG5
//
//  Created by Nathan Racklyeft on 3/26/16.
//  Copyright © 2016 Nathan Racklyeft. All rights reserved.
//

import Foundation


public enum TransmitterStatus {
    public typealias RawValue = UInt8

    case OK
    case LowBattery
    case Unknown(RawValue)

    init(rawValue: RawValue) {
        switch rawValue {
        case 0:
            self = .OK
        case 0x81:
            self = .LowBattery
        default:
            self = .Unknown(rawValue)
        }
    }
}


extension TransmitterStatus: Equatable { }

public func ==(lhs: TransmitterStatus, rhs: TransmitterStatus) -> Bool {
    switch (lhs, rhs) {
    case (.OK, .OK), (.LowBattery, .LowBattery):
        return true
    case (.Unknown(let left), .Unknown(let right)) where left == right:
        return true
    default:
        return false
    }
}
