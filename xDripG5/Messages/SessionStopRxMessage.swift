//
//  SessionStopRxMessage.swift
//  xDripG5
//
//  Created by Nathan Racklyeft on 6/4/16.
//  Copyright © 2016 Nathan Racklyeft. All rights reserved.
//

import Foundation


struct SessionStopRxMessage {
    static let opcode: UInt8 = 0x29
    let status: TransmitterStatus
    let received: UInt8
    let sessionStopTime: UInt32
    let sessionStartTime: UInt32
    let transmitterTime: UInt32

    init?(data: NSData) {
        guard data.length == 17 && data.crcValid() else {
            return nil
        }

        guard data[0] == self.dynamicType.opcode else {
            return nil
        }

        status = TransmitterStatus(rawValue: data[1])
        received = data[2]
        sessionStopTime = data[3...6]
        sessionStartTime = data[7...10]
        transmitterTime = data[11...14]
    }
}
