//
//  G7GlucoseMessageTests.swift
//  CGMBLEKitTests
//
//  Created by Pete Schwamb on 9/25/22.
//  Copyright © 2022 LoopKit Authors. All rights reserved.
//

import XCTest
@testable import CGMBLEKit

final class G7GlucoseMessageTests: XCTestCase {

    func testG7MessageData() {
        let data = Data(hexadecimalString: "4e00c35501002601000106008a00060187000f")!
        let message = G7GlucoseMessage(data: data)!

        XCTAssertEqual(138, message.glucose)
        XCTAssertEqual(87491, message.timestamp)
        XCTAssert(!message.glucoseIsDisplayOnly)
    }

    func testG7MessageDataWithCalibration() {
        let data = Data(hexadecimalString: "4e000ec10d00c00b00010000680006fe63001f")!
        let message = G7GlucoseMessage(data: data)!

        XCTAssertEqual(104, message.glucose)
        XCTAssertEqual(901390, message.timestamp)
        XCTAssert(message.glucoseIsDisplayOnly)
    }
}
