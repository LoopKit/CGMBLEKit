//
//  TransmitterVersionRxMessage.swift
//  xDripG5
//
//  Created by Nate Racklyeft on 9/29/16.
//  Copyright © 2016 Nathan Racklyeft. All rights reserved.
//

import Foundation


public struct TransmitterVersionRxMessage: TransmitterRxMessage {
    public let status: UInt8
    public let firmwareVersion: [UInt8]
    /// Lifetime the transmitter reports for itself (stock G6 = 90, Anubis-modded G6 = 180).
    public let transmitterExpiryInDays: UInt16

    public init?(data: Data) {
        guard data.count == 19 && data.isCRCValid else {
            return nil
        }

        guard data.starts(with: .transmitterVersionRx) else {
            return nil
        }

        status = data[1]
        firmwareVersion = data[2..<6].map { $0 }
        transmitterExpiryInDays = (UInt16(data[14]) << 8) + UInt16(data[13])
    }

    /// Heuristic borrowed from xDrip4iOS: Anubis-modded G6 transmitters
    /// report a 180-day expiry in the version-rx frame; stock G6 reports 90.
    public var isAnubis: Bool {
        return transmitterExpiryInDays == 180
    }
}
