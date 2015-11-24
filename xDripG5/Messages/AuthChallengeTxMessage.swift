//
//  AuthChallengeTxMessage.swift
//  xDrip5
//
//  Created by Nathan Racklyeft on 11/22/15.
//  Copyright © 2015 Nathan Racklyeft. All rights reserved.
//

import Foundation


struct AuthChallengeTxMessage: TransmitterTxMessage {
    let opcode: UInt8 = 0x4
    let challengeHash: NSData

    var byteSequence: [Any] {
        return [opcode, challengeHash]
    }
}
