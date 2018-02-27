//
//  CalibrateGlucoseRxMessage.swift
//  xDripG5
//
//  Created by Paul Dickens on 25/02/2018.
//  Copyright © 2018 LoopKit Authors. All rights reserved.
//

import Foundation


public struct CalibrateGlucoseRxMessage: TransmitterRxMessage {
    static let opcode: UInt8 = 0x35

    init?(data: Data) {
        guard data.count == 5 && data.crcValid() else {
            return nil
        }

        guard data[0] == type(of: self).opcode else {
            return nil
        }
    }
}
