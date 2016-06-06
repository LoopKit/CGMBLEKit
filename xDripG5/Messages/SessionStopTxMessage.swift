//
//  SessionStopTxMessage.swift
//  xDripG5
//
//  Created by Nathan Racklyeft on 3/26/16.
//  Copyright © 2016 Nathan Racklyeft. All rights reserved.
//

import Foundation


struct SessionStopTxMessage: TransmitterTxMessage {
    let opcode: UInt8 = 0x28
    let stopTime: UInt32

    var byteSequence: [Any] {
        return [opcode, stopTime]
    }
}
