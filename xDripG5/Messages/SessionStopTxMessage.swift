//
//  SessionStopTxMessage.swift
//  xDripG5
//
//  Created by Nathan Racklyeft on 3/26/16.
//  Copyright © 2016 Nathan Racklyeft. All rights reserved.
//

import Foundation


struct SessionStopTxMessage: TimedTransmitterTxMessage {
    static func createRxMessage(data: Data) -> TransmitterRxMessage? {
        return SessionStopRxMessage(data: data)
    }

    let opcode: UInt8 = 0x28
    let date: Date

    func data(activationDate: Date) -> Data {
        let stopTime = UInt32(date.timeIntervalSince(activationDate))
        let byteSequence: [Any] = [opcode, stopTime]
        return Data.fromByteSequence(byteSequence, hasCRC: true)
    }
}
