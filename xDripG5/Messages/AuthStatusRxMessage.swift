//
//  AuthStatusRxMessage.swift
//  xDrip5
//
//  Created by Nathan Racklyeft on 11/22/15.
//  Copyright © 2015 Nathan Racklyeft. All rights reserved.
//

import Foundation


struct AuthStatusRxMessage: TransmitterRxMessage {
    static let opcode: UInt8 = 0x5
    let authenticated: UInt8
    let bonded: UInt8

    init?(data: NSData) {
        if data.length >= 3 {
            if data[0] == self.dynamicType.opcode {
                self.authenticated = data[1]
                self.bonded = data[2]
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
}
