//
//  NSData.swift
//  Naterade
//
//  Created by Nathan Racklyeft on 9/2/15.
//  Copyright © 2015 Nathan Racklyeft. All rights reserved.
//

import Foundation


public extension NSData {
    @nonobjc subscript(index: Int) -> Int8 {
        let bytes: [Int8] = self[index...index]

        return bytes[0]
    }

    @nonobjc subscript(index: Int) -> UInt8 {
        let bytes: [UInt8] = self[index...index]

        return bytes[0]
    }

    @nonobjc subscript(range: Range<Int>) -> UInt16 {
        return self[range][0]
    }

    @nonobjc subscript(range: Range<Int>) -> UInt32 {
        return self[range][0]
    }

    subscript(range: Range<Int>) -> [Int8] {
        var dataArray = [Int8](count: range.count, repeatedValue: 0)
        self.getBytes(&dataArray, range: NSRange(range))

        return dataArray
    }

    subscript(range: Range<Int>) -> [UInt8] {
        var dataArray = [UInt8](count: range.count, repeatedValue: 0)
        self.getBytes(&dataArray, range: NSRange(range))

        return dataArray
    }

    subscript(range: Range<Int>) -> [UInt16] {
        var dataArray = [UInt16](count: range.count / 2, repeatedValue: 0)
        self.getBytes(&dataArray, range: NSRange(range))

        return dataArray
    }

    subscript(range: Range<Int>) -> [UInt32] {
        var dataArray = [UInt32](count: range.count / 4, repeatedValue: 0)
        self.getBytes(&dataArray, range: NSRange(range))

        return dataArray
    }

    subscript(range: Range<Int>) -> NSData {
        return subdataWithRange(NSRange(range))
    }
}
