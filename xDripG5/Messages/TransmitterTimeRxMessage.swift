//
//  TransmitterTimeRxMessage.swift
//  xDrip5
//
//  Created by Nathan Racklyeft on 11/23/15.
//  Copyright © 2015 Nathan Racklyeft. All rights reserved.
//

import Foundation


struct TransmitterTimeRxMessage: TransmitterRxMessage {
    static let opcode: UInt8 = 0x25
    let status: UInt8
    let currentTime: UInt32
    let sessionStartTime: UInt32

    init?(data: NSData) {
        if data.length >= 10 {
            if data[0] == self.dynamicType.opcode {
                status = data[1]
                currentTime = data[2...5]
                sessionStartTime = data[6...9]
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
}