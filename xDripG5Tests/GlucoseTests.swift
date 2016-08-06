//
//  GlucoseTests.swift
//  xDripG5
//
//  Created by Nate Racklyeft on 8/6/16.
//  Copyright © 2016 Nathan Racklyeft. All rights reserved.
//

import XCTest
import HealthKit
@testable import xDripG5

class GlucoseTests: XCTestCase {

    var timeMessage: TransmitterTimeRxMessage!
    let calendar = NSCalendar(identifier: NSCalendarIdentifierGregorian)
    var activationDate: NSDate!

    override func setUp() {
        super.setUp()

        let data = NSData(hexadecimalString: "2500470272007cff710001000000fa1d")!
        timeMessage = TransmitterTimeRxMessage(data: data)!

        calendar?.timeZone = NSTimeZone(name: "UTC")!
        activationDate = calendar?.dateWithEra(1, year: 2016, month: 10, day: 1, hour: 0, minute: 0, second: 0, nanosecond: 0)!
    }

    func testMessageData() {
        let data = NSData(hexadecimalString: "3100680a00008a715700cc0006ffc42a")!
        let message = GlucoseRxMessage(data: data)!
        let glucose = Glucose(glucoseMessage: message, timeMessage: timeMessage, activationDate: activationDate)

        XCTAssertEqual(TransmitterStatus.OK, glucose.status)
        XCTAssertEqual(calendar?.dateWithEra(1, year: 2016, month: 12, day: 6, hour: 7, minute: 51, second: 38, nanosecond: 0)!, glucose.readDate)
        XCTAssertEqual(calendar?.dateWithEra(1, year: 2016, month: 12, day: 26, hour: 11, minute: 16, second: 12, nanosecond: 0)!, glucose.sessionStartDate)
        XCTAssertFalse(glucose.isDisplayOnly)
        XCTAssertEqual(204, glucose.glucose?.doubleValueForUnit(HKUnit.milligramsPerDeciliter()))
        XCTAssertEqual(CalibrationState.OK, glucose.state)
        XCTAssertEqual(-1, glucose.trend)
    }

    func testNegativeTrend() {
        let data = NSData(hexadecimalString: "31006f0a0000be7957007a0006e4818d")!
        let message = GlucoseRxMessage(data: data)!
        let glucose = Glucose(glucoseMessage: message, timeMessage: timeMessage, activationDate: activationDate)

        XCTAssertEqual(TransmitterStatus.OK, glucose.status)
        XCTAssertEqual(calendar?.dateWithEra(1, year: 2016, month: 12, day: 6, hour: 8, minute: 26, second: 38, nanosecond: 0)!, glucose.readDate)
        XCTAssertFalse(glucose.isDisplayOnly)
        XCTAssertEqual(122, glucose.glucose?.doubleValueForUnit(HKUnit.milligramsPerDeciliter()))
        XCTAssertEqual(CalibrationState.OK, glucose.state)
        XCTAssertEqual(-28, glucose.trend)
    }

    func testDisplayOnly() {
        let data = NSData(hexadecimalString: "3100700a0000f17a5700584006e3cee9")!
        let message = GlucoseRxMessage(data: data)!
        let glucose = Glucose(glucoseMessage: message, timeMessage: timeMessage, activationDate: activationDate)

        XCTAssertEqual(TransmitterStatus.OK, glucose.status)
        XCTAssertEqual(calendar?.dateWithEra(1, year: 2016, month: 12, day: 6, hour: 8, minute: 31, second: 45, nanosecond: 0)!, glucose.readDate)
        XCTAssertTrue(glucose.isDisplayOnly)
        XCTAssertEqual(88, glucose.glucose?.doubleValueForUnit(HKUnit.milligramsPerDeciliter()))
        XCTAssertEqual(CalibrationState.OK, glucose.state)
        XCTAssertEqual(-29, message.trend)
    }

    func testOldTransmitter() {
        let data = NSData(hexadecimalString: "3100aa00000095a078008b00060a8b34")!
        let message = GlucoseRxMessage(data: data)!
        let glucose = Glucose(glucoseMessage: message, timeMessage: timeMessage, activationDate: activationDate)

        XCTAssertEqual(TransmitterStatus.OK, glucose.status)
        XCTAssertEqual(calendar?.dateWithEra(1, year: 2016, month: 12, day: 31, hour: 11, minute: 57, second: 09, nanosecond: 0)!, glucose.readDate)  // 90 days, status is still OK
        XCTAssertFalse(glucose.isDisplayOnly)
        XCTAssertEqual(139, glucose.glucose?.doubleValueForUnit(HKUnit.milligramsPerDeciliter()))
        XCTAssertEqual(CalibrationState.OK, glucose.state)
        XCTAssertEqual(10, message.trend)
    }
    
}
