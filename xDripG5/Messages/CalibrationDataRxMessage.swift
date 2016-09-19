//
//  CalibrationDataRxMessage.swift
//  Pods
//
//  Created by Nate Racklyeft on 9/18/16.
//
//

import Foundation


struct CalibrationDataRxMessage: TransmitterRxMessage {
    static let opcode: UInt8 = 0x33

    init?(data: Data) {
        guard data.count == 19 && data.crcValid() else {
            return nil
        }

        guard data[0] == type(of: self).opcode else {
            return nil
        }
    }
}
