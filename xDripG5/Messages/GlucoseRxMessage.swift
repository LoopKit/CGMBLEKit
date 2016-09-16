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

    init?(data: Data) {
        guard data.count == 16 && data.crcValid() else {
            return nil
        }

        guard data[0] == type(of: self).opcode else {
            return nil
        }

        status = data[1]
        sequence = data[2..<6]
        timestamp = data[6..<10]

        let glucoseBytes: UInt16 = data[10..<12]
        glucoseIsDisplayOnly = (glucoseBytes & 0xf000) > 0
        glucose = glucoseBytes & 0xfff

        state = data[12]
        trend = Int8(bitPattern: data[13])
    }
}


extension GlucoseRxMessage: Equatable {
}

public func ==(lhs: GlucoseRxMessage, rhs: GlucoseRxMessage) -> Bool {
    return lhs.sequence == rhs.sequence && lhs.timestamp == rhs.timestamp
}
