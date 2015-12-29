//
//  GlucoseTxMessage.swift
//  xDrip5
//
//  Created by Nathan Racklyeft on 11/23/15.
//  Copyright © 2015 Nathan Racklyeft. All rights reserved.
//

import Foundation


struct GlucoseTxMessage: TransmitterTxMessage {
    let opcode: UInt8 = 0x30
    let crc: UInt16 = 0x3653  // Too lazy to convert this CRC function to Swift

    var byteSequence: [Any] {
        return [opcode, crc]
    }
}
