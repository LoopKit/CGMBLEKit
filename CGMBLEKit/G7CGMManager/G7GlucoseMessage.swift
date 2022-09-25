//
//  G7GlucoseMessage.swift
//  CGMBLEKit
//
//  Created by Pete Schwamb on 9/24/22.
//  Copyright © 2022 LoopKit Authors. All rights reserved.
//

import Foundation

public struct G7GlucoseMessage: Equatable {
    //public let status: UInt8
    //public let sequence: UInt32
    public let glucose: UInt16
    public let glucoseIsDisplayOnly: Bool
    public let timestamp: UInt32 // Seconds since pairing

    init?(data: Data) {
        //    0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18
        // 0x4e 00 d5 07 00 00 09 00 00 01 05 00 61 00 06 01 ff ff 0e
        //   4e 00 b2 47 01 00 1a 01 00 01 05 00 9c000600a4000f

        guard data.count >= 19 else {
            return nil
        }

        guard data[1] == 00 else {
            return nil
        }

        let glucoseBytes = data[12..<14].to(UInt16.self)
        glucoseIsDisplayOnly = (glucoseBytes & 0xf000) > 0
        glucose = glucoseBytes & 0xfff

        timestamp = data[2..<6].toInt()
    }
}
