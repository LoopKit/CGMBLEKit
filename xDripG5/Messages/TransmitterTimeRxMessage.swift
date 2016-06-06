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
    let status: TransmitterStatus
    let currentTime: UInt32
    let sessionStartTime: UInt32

    init?(data: NSData) {
        guard data.length == 16 && data.crcValid() else {
            return nil
        }

        guard data[0] == self.dynamicType.opcode else {
            return nil
        }

        status = TransmitterStatus(rawValue: data[1])
        currentTime = data[2...5]
        sessionStartTime = data[6...9]
    }
}