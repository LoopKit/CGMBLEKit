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

    var data: NSData { get }

}


extension TransmitterTxMessage {
    var data: NSData {
        let data = NSMutableData()

        for item in byteSequence {
            switch item {
            case let i as Int8:
                var value = i

                data.appendBytes(&value, length: 1)
            case let i as UInt8:
                var value = i

                data.appendBytes(&value, length: 1)
            case let i as UInt16:
                var value = i

                data.appendBytes(&value, length: 2)
            case let i as UInt32:
                var value = i

                data.appendBytes(&value, length: 4)
            case let i as NSData:
                data.appendData(i)
            default:
                fatalError("\(item) not supported")
            }
        }

        return data
    }
}


protocol TransmitterRxMessage {

    init?(data: NSData)

}