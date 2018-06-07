//
//  Opcode.swift
//  xDripG5
//
//  Copyright © 2018 LoopKit Authors. All rights reserved.
//

import Foundation

enum Opcode: UInt8 {
    // Auth
    case authRequestTx = 0x01

    case authRequestRx = 0x03
    case authChallengeTx = 0x04
    case authChallengeRx = 0x05
    case keepAlive = 0x06 // auth; setAdvertisementParametersTx for control
    case bondRequest = 0x07
    
    // Control
    case disconnectTx = 0x09
    
    case setAdvertisementParametersRx = 0x1c

    case firmwareVersionTx = 0x20
    case firmwareVersionRx = 0x21
    case batteryStatusTx = 0x22
    case batteryStatusRx = 0x23
    case transmitterTimeTx = 0x24
    case transmitterTimeRx = 0x25
    case sessionStartTx = 0x26
    case sessionStartRx = 0x27
    case sessionStopTx = 0x28
    case sessionStopRx = 0x29

    case glucoseTx = 0x30
    case glucoseRx = 0x31
    case calibrationDataTx = 0x32
    case calibrationDataRx = 0x33
    case calibrateGlucoseTx = 0x34
    case calibrateGlucoseRx = 0x35

    case glucoseHistoryTx = 0x3e

    case resetTx = 0x42
    case resetRx = 0x43

    case transmitterVersionTx = 0x4a
    case transmitterVersionRx = 0x4b
    
    case glucoseG6Tx = 0x4e
    case glucoseG6Rx = 0x4f

    case glucoseBackfillTx = 0x50
    case glucoseBackfillRx = 0x51
}


extension Data {
    init(for opcode: Opcode) {
        self.init(bytes: [opcode.rawValue])
    }

    func starts(with opcode: Opcode) -> Bool {
        guard count > 0 else {
            return false
        }

        return self[startIndex] == opcode.rawValue
    }
}
