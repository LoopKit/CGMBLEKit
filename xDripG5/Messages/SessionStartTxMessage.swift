//
//  SessionStartTxMessage.swift
//  xDripG5
//
//  Created by Nathan Racklyeft on 3/26/16.
//  Copyright © 2016 Nathan Racklyeft. All rights reserved.
//

import Foundation


struct SessionStartTxMessage: TransmitterTxMessage {
    let opcode: UInt8 = 0x26
    let startTime: UInt32

    var byteSequence: [Any] {
        return [opcode, startTime]
    }
}
