//
//  Opcode.swift
//  xDripG5
//
//  Copyright © 2018 LoopKit Authors. All rights reserved.
//


enum Opcode: UInt8 {
    case authRequestTx = 0x01
    case authRequestRx = 0x03
    case authChallengeTx = 0x04
    case authChallengeRx = 0x05
    case keepAlive = 0x06
    case bondRequest = 0x07

    case disconnectTx = 0x09

    case firmwareVersionTx = 0x20

    case batteryStatusTx = 0x22

    case transmitterTimeTx = 0x24
    case transmitterTimeRx = 0x25
    case sessionStartTx = 0x26
    case sessionStartRx = 0x27

    case sessionStopTx = 0x28
    case sessionStopRx = 0x29
    case glucoseTx = 0x30
    case glucoseRx = 0x31

    case calibrationDataRx = 0x33
    case calibrateGlucoseTx = 0x34

    case glucoseHistoryTx = 0x3e

    case transmitterVersionTx = 0x4a
    case transmitterVersionRx = 0x4b
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
