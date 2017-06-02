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
    let singleUseToken: Data
    let endByte: UInt8 = 0x2

    init() {
        var UUIDBytes = [UInt8](repeating: 0, count: 16)

        NSUUID().getBytes(&UUIDBytes)

        singleUseToken = Data(bytes: UUIDBytes[0..<8])
    }

    var byteSequence: [Any] {
        return [opcode, singleUseToken, endByte]
    }
}
