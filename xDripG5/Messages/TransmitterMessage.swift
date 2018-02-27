//
//  TransmitterCommand.swift
//  xDrip5
//
//  Created by Nathan Racklyeft on 11/22/15.
//  Copyright © 2015 Nathan Racklyeft. All rights reserved.
//

import Foundation


protocol TransmitterTxMessage {

    var byteSequence: [Any] { get }

    var data: Data { get }

    var hasCRC: Bool { get }

}

extension TransmitterTxMessage {
    var data: Data {
        return Data.fromByteSequence(byteSequence, hasCRC: hasCRC)
    }

    var hasCRC: Bool {
        return false
    }
}


extension Data {
    static func fromByteSequence(_ byteSequence: [Any], hasCRC: Bool = false) -> Data {
        let data = NSMutableData()

        for item in byteSequence {
            switch item {
            case let i as Int8:
                var value = i

                data.append(&value, length: 1)
            case let i as UInt8:
                var value = i

                data.append(&value, length: 1)
            case let i as UInt16:
                var value = i

                data.append(&value, length: 2)
            case let i as UInt32:
                var value = i

                data.append(&value, length: 4)
            case let i as Data:
                data.append(i)
            default:
                fatalError("\(item) not supported")
            }
        }

        if hasCRC {
            var value = (data as Data).crc16() as UInt16
            data.append(&value, length: 2)
        }

        return data as Data
    }
}


protocol TimedTransmitterTxMessage {

    static func createRxMessage(data: Data) -> TransmitterRxMessage?

    var opcode: UInt8 { get }

    func data(activationDate: Date) -> Data

}


protocol TransmitterRxMessage {

    init?(data: Data)

}
