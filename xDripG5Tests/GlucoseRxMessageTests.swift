//
//  GlucoseRxMessageTests.swift
//  xDripG5
//
//  Created by Nathan Racklyeft on 3/5/16.
//  Copyright © 2016 Nathan Racklyeft. All rights reserved.
//

import XCTest
@testable import xDripG5


class GlucoseRxMessageTests: XCTestCase {

    func testMessageData() {
        let data = NSData(hexadecimalString: "3100680a00008a715700cc0006ffc42a")!
        let message = GlucoseRxMessage(data: data)!

        XCTAssertEqual(0, message.status)
        XCTAssertEqual(2664, message.sequence)
        XCTAssertEqual(5730698, message.timestamp)
        XCTAssertFalse(message.glucoseIsDisplayOnly)
        XCTAssertEqual(204, message.glucose)
        XCTAssertEqual(6, message.state)
        XCTAssertEqual(-1, message.trend)
    }

    func testNegativeTrend() {
        let data = NSData(hexadecimalString: "31006f0a0000be7957007a0006e4818d")!
        let message = GlucoseRxMessage(data: data)!

        XCTAssertEqual(0, message.status)
        XCTAssertEqual(2671, message.sequence)
        XCTAssertEqual(5732798, message.timestamp)
        XCTAssertFalse(message.glucoseIsDisplayOnly)
        XCTAssertEqual(122, message.glucose)
        XCTAssertEqual(6, message.state)
        XCTAssertEqual(-28, message.trend)
    }

    func testDisplayOnly() {
        let data = NSData(hexadecimalString: "3100700a0000f17a5700584006e3cee9")!
        let message = GlucoseRxMessage(data: data)!

        XCTAssertEqual(0, message.status)
        XCTAssertEqual(2672, message.sequence)
        XCTAssertEqual(5733105, message.timestamp)
        XCTAssertTrue(message.glucoseIsDisplayOnly)
        XCTAssertEqual(88, message.glucose)
        XCTAssertEqual(6, message.state)
        XCTAssertEqual(-29, message.trend)
    }
    
}
