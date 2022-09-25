//
//  G7BackfillMessage.swift
//  CGMBLEKit
//
//  Created by Pete Schwamb on 9/25/22.
//  Copyright © 2022 LoopKit Authors. All rights reserved.
//

import Foundation

public struct G7BackfillMessage: Equatable {
    //public let status: UInt8
    //public let sequence: UInt32
    public let glucose: UInt16
    public let glucoseIsDisplayOnly: Bool
    public let timestamp: UInt32 // Seconds since pairing

    init?(data: Data) {
        //    0  1  2  3  4  5  6  7  8
        //   45 a1 00 00 96 00 06 0f fc

        guard data.count == 9 else {
            return nil
        }

        timestamp = data[0..<4].toInt()

        let glucoseBytes = data[4..<6].to(UInt16.self)
        glucoseIsDisplayOnly = (glucoseBytes & 0xf000) > 0
        glucose = glucoseBytes & 0xfff

    }
}
