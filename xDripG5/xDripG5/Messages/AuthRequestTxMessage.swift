//
//  AuthRequestTxMessage.swift
//  xDrip5
//
//  Created by Nathan Racklyeft on 11/22/15.
//  Copyright © 2015 Nathan Racklyeft. All rights reserved.
//

import Foundation


struct AuthRequestTxMessage: TransmitterTxMessage {
    let opcode: UInt8 = 0x1
    let singleUseToken: NSData
    let endByte: UInt8 = 0x2

    init() {
        var UUIDBytes = [UInt8](count: 16, repeatedValue: 0)

        NSUUID().getUUIDBytes(&UUIDBytes)

        singleUseToken = NSData(bytes: &UUIDBytes, length: 8)
    }

    var byteSequence: [Any] {
        return [opcode, singleUseToken, endByte]
    }
}
