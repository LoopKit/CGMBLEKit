//
//  NSData+CRC.swift
//  xDripG5
//
//  Created by Nathan Racklyeft on 4/7/16.
//  Copyright © 2016 Nathan Racklyeft. All rights reserved.
//

import Foundation


/**
 CRC-CCITT (XModem)

 [http://www.lammertbies.nl/comm/info/crc-calculation.html]()
 
 [http://web.mit.edu/6.115/www/amulet/xmodem.htm]()
 */
func CRCCCITTXModem(bytes: [UInt8], count: Int? = nil) -> UInt16 {
    let count = count ?? bytes.count

    var crc: UInt16 = 0

    for byte in bytes[0..<count] {
        crc ^= UInt16(byte) << 8

        for _ in 0..<8 {
            if crc & 0x8000 != 0 {
                crc = crc << 1 ^ 0x1021
            } else {
                crc = crc << 1
            }
        }
    }

    return crc
}


extension UInt8 {
    func crc16() -> UInt16 {
        return CRCCCITTXModem([self])
    }
}


extension NSData {
    func crc16() -> UInt16 {
        return CRCCCITTXModem(self[0..<length])
    }

    func crcValid() -> Bool {
        return CRCCCITTXModem(self[0..<length-2]) == self[length-2..<length]
    }
}
