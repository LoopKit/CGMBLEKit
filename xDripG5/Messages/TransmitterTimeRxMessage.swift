//
//  TransmitterTimeRxMessage.swift
//  xDrip5
//
//  Created by Nathan Racklyeft on 11/23/15.
//  Copyright © 2015 Nathan Racklyeft. All rights reserved.
//

import Foundation


struct TransmitterTimeRxMessage: TransmitterRxMessage {
    static let opcode: UInt8 = 0x25
    let status: UInt8
    let currentTime: UInt32
    let sessionStartTime: UInt32

    init?(data: Data) {
        guard data.count == 16 && data.crcValid() else {
            return nil
        }

        guard data[0] == type(of: self).opcode else {
            return nil
        }

        status = data[1]
        currentTime = data.subdata(in: 2..<6).withUnsafeBytes { $0.pointee }
        sessionStartTime = data.subdata(in: 6..<10).withUnsafeBytes { $0.pointee }
    }
}

extension TransmitterTimeRxMessage: Equatable { }

func ==(lhs: TransmitterTimeRxMessage, rhs: TransmitterTimeRxMessage) -> Bool {
    return lhs.currentTime == rhs.currentTime
}
