//
//  BondRequestTxMessage.swift
//  xDrip5
//
//  Created by Nathan Racklyeft on 11/23/15.
//  Copyright © 2015 Nathan Racklyeft. All rights reserved.
//

import Foundation


struct BondRequestTxMessage: TransmitterTxMessage {
    let opcode: UInt8 = 0x7

    var byteSequence: [Any] {
        return [opcode]
    }
}