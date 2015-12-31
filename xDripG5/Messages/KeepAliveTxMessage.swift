//
//  KeepAliveTxMessage.swift
//  xDrip5
//
//  Created by Nathan Racklyeft on 11/23/15.
//  Copyright © 2015 Nathan Racklyeft. All rights reserved.
//

import Foundation


struct KeepAliveTxMessage: TransmitterTxMessage {
    let opcode: UInt8 = 0x6
    let time: UInt8

    var byteSequence: [Any] {
        return [opcode, time]
    }
}