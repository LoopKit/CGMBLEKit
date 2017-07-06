//
//  SessionStartRxMessage.swift
//  xDripG5
//
//  Created by Nathan Racklyeft on 6/4/16.
//  Copyright © 2016 Nathan Racklyeft. All rights reserved.
//

import Foundation


struct SessionStartRxMessage {
    static let opcode: UInt8 = 0x27
    let status: UInt8
    let received: UInt8

    // I've only seen examples of these 2 values matching
    let requestedStartTime: UInt32
    let sessionStartTime: UInt32

    let transmitterTime: UInt32

    init?(data: Data) {
        guard data.count == 17 && data.crcValid() else {
            return nil
        }

        guard data[0] == type(of: self).opcode else {
            return nil
        }

        status = data[1]
        received = data[2]
        requestedStartTime = data.subdata(in: 3..<7).withUnsafeBytes { $0.pointee }
        sessionStartTime = data.subdata(in: 7..<11).withUnsafeBytes { $0.pointee }
        transmitterTime = data.subdata(in: 11..<15).withUnsafeBytes { $0.pointee }
    }
}
