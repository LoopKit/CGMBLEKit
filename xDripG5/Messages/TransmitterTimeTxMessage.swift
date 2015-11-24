//
//  TransmitterTimeTxMessage.swift
//  xDrip5
//
//  Created by Nathan Racklyeft on 11/23/15.
//  Copyright © 2015 Nathan Racklyeft. All rights reserved.
//

import Foundation


struct TransmitterTimeTxMessage: TransmitterTxMessage {
    let opcode: UInt8 = 0x24
    let crc: UInt16 = 0x64e6  // Too lazy to convert this CRC function to Swift

    var byteSequence: [Any] {
        return [opcode, crc]
    }
}
