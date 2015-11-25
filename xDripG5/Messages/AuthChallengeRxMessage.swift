//
//  AuthChallengeRxMessage.swift
//  xDrip5
//
//  Created by Nathan Racklyeft on 11/22/15.
//  Copyright © 2015 Nathan Racklyeft. All rights reserved.
//

import Foundation


struct AuthChallengeRxMessage: TransmitterRxMessage {
    static let opcode: UInt8 = 0x3
    let tokenHash: NSData
    let challenge: NSData

    init?(data: NSData) {
        if data.length >= 17 {
            if data[0] == self.dynamicType.opcode {
                tokenHash = data[1..<9]
                challenge = data[9..<17]
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
}