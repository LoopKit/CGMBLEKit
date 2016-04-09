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

    var byteSequence: [Any] {
        return [opcode, opcode.crc16()]
    }
}
