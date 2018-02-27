//
//  CalibrateGlucoseTxMessage.swift
//  xDripG5
//
//  Created by Nathan Racklyeft on 3/26/16.
//  Copyright © 2016 Nathan Racklyeft. All rights reserved.
//

import Foundation


struct CalibrateGlucoseTxMessage: TimedTransmitterTxMessage {
    static func createRxMessage(data: Data) -> TransmitterRxMessage? {
        return CalibrateGlucoseRxMessage(data: data)
    }

    let opcode: UInt8 = 0x34
    let date: Date
    let glucose: UInt16

    func data(activationDate: Date) -> Data {
        let calibrationTime = UInt32(date.timeIntervalSince(activationDate))
        let byteSequence: [Any] = [opcode, glucose, calibrationTime]
        return Data.fromByteSequence(byteSequence, hasCRC: true)
    }
}
