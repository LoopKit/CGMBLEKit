//
//  NSData.swift
//  Naterade
//
//  Created by Nathan Racklyeft on 9/2/15.
//  Copyright © 2015 Nathan Racklyeft. All rights reserved.
//

import Foundation


public extension Data {
    /*@nonobjc subscript(index: Int) -> Int8 {
        let bytes: [Int8] = self[index...index]

        return bytes[0]
    }

    @nonobjc subscript(index: Int) -> UInt8 {
        let bytes: [UInt8] = self[index...index]

        return bytes[0]
    }
*/
    @nonobjc subscript(range: Range<Int>) -> UInt16 {
        var dataArray: UInt16 = 0
        let buffer = UnsafeMutableBufferPointer(start: &dataArray, count: range.count)
        _ = self.copyBytes(to: buffer, from: range)

        return dataArray
    }

    @nonobjc subscript(range: Range<Int>) -> UInt32 {
        var dataArray: UInt32 = 0
        let buffer = UnsafeMutableBufferPointer(start: &dataArray, count: range.count)
        _ = self.copyBytes(to: buffer, from: range)

        return dataArray
    }
/*
    subscript(range: Range<Int>) -> [Int8] {
        var dataArray = [Int8](repeating: 0, count: range.count)
        let buffer = UnsafeMutableBufferPointer(start: &dataArray, count: range.count)
        _ = self.copyBytes(to: buffer, from: range)

        return dataArray
    }
*/
    subscript(range: Range<Int>) -> [UInt8] {
        var dataArray = [UInt8](repeating: 0, count: range.count)
        self.copyBytes(to: &dataArray, from: range)

        return dataArray
    }
/*
    subscript(range: Range<Int>) -> [UInt16] {
        var dataArray = [UInt16](repeating: 0, count: range.count / 2)
        let buffer = UnsafeMutableBufferPointer(start: &dataArray, count: range.count)
        _ = self.copyBytes(to: buffer, from: range)

        return dataArray
    }

    subscript(range: Range<Int>) -> [UInt32] {
        var dataArray = [UInt32](repeating: 0, count: range.count / 4)
        let buffer = UnsafeMutableBufferPointer(start: &dataArray, count: range.count)
        _ = self.copyBytes(to: buffer, from: range)

        return dataArray
    }
 */
}
