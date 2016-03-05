//
//  GlucoseRxMessage.swift
//  xDrip5
//
//  Created by Nathan Racklyeft on 11/23/15.
//  Copyright © 2015 Nathan Racklyeft. All rights reserved.
//

import Foundation


public struct GlucoseRxMessage: TransmitterRxMessage {
    static let opcode: UInt8 = 0x31
    public let status: UInt8
    public let sequence: UInt32
    public let timestamp: UInt32
    public let glucoseIsDisplayOnly: Bool
    public let glucose: UInt16
    public let state: UInt8
    public let trend: Int8

    init?(data: NSData) {
        if data.length >= 14 {
            if data[0] == self.dynamicType.opcode {
                status = data[1]
                sequence = data[2...5]
                timestamp = data[6...9]

                let glucoseBytes: UInt16 = data[10...11]
                glucoseIsDisplayOnly = (glucoseBytes & 0xf000) > 0
                glucose = glucoseBytes & 0xfff

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


extension GlucoseRxMessage: Equatable {
}

public func ==(lhs: GlucoseRxMessage, rhs: GlucoseRxMessage) -> Bool {
    return lhs.sequence == rhs.sequence
}
