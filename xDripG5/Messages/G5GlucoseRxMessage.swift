//
//  G5GlucoseRxMessage.swift
//  xDrip5
//
//  Created by Nathan Racklyeft on 11/23/15.
//  Copyright © 2015 Nathan Racklyeft. All rights reserved.
//

import Foundation


public struct G5GlucoseRxMessage: GlucoseRxMessage {
    static let opcode: UInt8 = 0x31
    let glucoseIsDisplayOnly: Bool = false  // TODO
    let status: UInt8
    let sequence: UInt32
    var glucoseValue: UInt16
    public let timestamp: UInt32
    public let state: UInt8
    public let trend: Int8

    public var glucose: UInt16{
        get{ return self.glucoseValue }
        set{ self.glucoseValue = newValue }
    }

    public init?(data: NSData) {
        if data.length >= 14 {
            if data[0] == self.dynamicType.opcode {
                status = data[1]
                sequence = data[2...5]
                timestamp = data[6...9]
                glucoseValue = data[10...11] & 0xfff
                state = data[12]
                trend = data[13]
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
}


extension G5GlucoseRxMessage: Equatable {
}

public func ==(lhs: G5GlucoseRxMessage, rhs: G5GlucoseRxMessage) -> Bool {
    return lhs.sequence == rhs.sequence
}
