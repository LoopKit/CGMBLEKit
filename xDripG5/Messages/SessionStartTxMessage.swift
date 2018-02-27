//
//  SessionStartTxMessage.swift
//  xDripG5
//
//  Created by Nathan Racklyeft on 3/26/16.
//  Copyright © 2016 Nathan Racklyeft. All rights reserved.
//

import Foundation


struct SessionStartTxMessage: TimedTransmitterTxMessage {
    static func createRxMessage(data: Data) -> TransmitterRxMessage? {
        return SessionStartRxMessage(data: data)
    }

    let opcode: UInt8 = 0x26
    let date: Date

    func data(activationDate: Date) -> Data {
        let startTime: UInt32 = UInt32(date.timeIntervalSince(activationDate))
        let startTimeEpoch: UInt32 = UInt32(date.timeIntervalSince1970)
        let byteSequence: [Any] = [opcode, startTime, startTimeEpoch]
        return Data.fromByteSequence(byteSequence, hasCRC: true)
    }
}
