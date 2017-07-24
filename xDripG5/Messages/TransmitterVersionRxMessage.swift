//
//  TransmitterVersionRxMessage.swift
//  xDripG5
//
//  Created by Nate Racklyeft on 9/29/16.
//  Copyright © 2016 Nathan Racklyeft. All rights reserved.
//

import Foundation


struct TransmitterVersionRxMessage: TransmitterRxMessage {
    static let opcode: UInt8 = 0x4b
    let status: UInt8
    let firmwareVersion: [UInt8]

    init?(data: Data) {
        guard data.count == 19 && data.crcValid() else {
            return nil
        }

        guard data[0] == type(of: self).opcode else {
            return nil
        }

        status = data[1]
        firmwareVersion = data.subdata(in: 2..<6).map({ $0 })
    }

}
