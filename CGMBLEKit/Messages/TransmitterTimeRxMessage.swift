//
//  TransmitterTimeRxMessage.swift
//  xDrip5
//
//  Created by Nathan Racklyeft on 11/23/15.
//  Copyright © 2015 Nathan Racklyeft. All rights reserved.
//

import Foundation


struct TransmitterTimeRxMessage: TransmitterRxMessage {
    // Dexcom reports UInt32.max when no sensor session is active.
    static let noActiveSessionStartTime = UInt32.max

    let status: UInt8
    let currentTime: UInt32
    let sessionStartTime: UInt32

    var hasValidSensorSession: Bool {
        return sessionStartTime != Self.noActiveSessionStartTime && sessionStartTime <= currentTime
    }

    init?(data: Data) {
        guard data.count == 16 && data.isCRCValid else {
            return nil
        }

        guard data.starts(with: .transmitterTimeRx) else {
            return nil
        }

        status = data[1]
        currentTime = data[2..<6].toInt()
        sessionStartTime = data[6..<10].toInt()

    }
}

extension TransmitterTimeRxMessage: Equatable { }

func ==(lhs: TransmitterTimeRxMessage, rhs: TransmitterTimeRxMessage) -> Bool {
    return lhs.currentTime == rhs.currentTime
}
