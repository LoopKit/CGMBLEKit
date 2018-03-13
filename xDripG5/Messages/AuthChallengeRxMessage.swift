//
//  AuthChallengeRxMessage.swift
//  xDrip5
//
//  Created by Nathan Racklyeft on 11/22/15.
//  Copyright © 2015 Nathan Racklyeft. All rights reserved.
//

import Foundation


struct AuthChallengeRxMessage: TransmitterRxMessage {
    let authenticated: UInt8
    let bonded: UInt8

    init?(data: Data) {
        guard data.count >= 3 else {
            return nil
        }

        guard data.starts(with: .authChallengeRx) else {
            return nil
        }

        authenticated = data[1]
        bonded = data[2]
    }
}
