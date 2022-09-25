//
//  G7GlucoseMessage.swift
//  CGMBLEKit
//
//  Created by Pete Schwamb on 9/24/22.
//  Copyright © 2022 LoopKit Authors. All rights reserved.
//

import Foundation

public struct G7GlucoseMessage {
    //public let status: UInt8
    //public let sequence: UInt32
    public let glucose: UInt16
    public let glucoseIsDisplayOnly: Bool

    init?(data: Data) {
        //    0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18
        // 0x4e 00 d5 07 00 00 09 00 00 01 05 00 61 00 06 01 ff ff 0e

        guard data.count >= 19 else {
            return nil
        }

        let glucoseBytes = data[11..<12].to(UInt16.self)
        glucoseIsDisplayOnly = (glucoseBytes & 0xf000) > 0
        glucose = glucoseBytes & 0xfff
    }
}
