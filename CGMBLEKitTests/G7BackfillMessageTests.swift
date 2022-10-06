//
//  G7BackfillMessageTests.swift
//  CGMBLEKitTests
//
//  Created by Pete Schwamb on 9/25/22.
//  Copyright © 2022 LoopKit Authors. All rights reserved.
//

import XCTest
@testable import CGMBLEKit

final class G7BackfillMessageTests: XCTestCase {

    func testG7BackfillMessage() {
        let data = Data(hexadecimalString: "45a100009600060ffc")!
        let message = G7BackfillMessage(data: data)!

        XCTAssertEqual(150, message.glucose)
        XCTAssertEqual(41285, message.timestamp)
    }

    func testG7BackfillMessageWarmup() {
        let data = Data(hexadecimalString: "50000000ffff01007f")!
        let message = G7BackfillMessage(data: data)!

        XCTAssertNil(message.glucose)
        XCTAssertNil(message.condition)
        XCTAssertNil(message.trend)
    }

    func testG7BackfillMessageMatchesGlucoseMessage() {

        let glucose = G7GlucoseMessage(data: Data(hexadecimalString: "4e00722000001e0000010600760006faffff0e")!)!
        let backfill = G7BackfillMessage(data: Data(hexadecimalString: "6c2000007600060efa")!)!

        XCTAssertEqual(glucose.glucoseTimestamp, backfill.timestamp)
        XCTAssertEqual(glucose.glucose, backfill.glucose)
        XCTAssertEqual(glucose.algorithmState, backfill.algorithmState)
        XCTAssertEqual(glucose.trend, backfill.trend)
    }

    func testG7BackfillMessageMatchesGlucoseMessage2() {

        let glucose = G7GlucoseMessage(data: Data(hexadecimalString: "4e0055710000630000010d008900060390000f")!)!
        let backfill = G7BackfillMessage(data: Data(hexadecimalString: "487100008900060f03")!)!

        XCTAssertEqual(glucose.glucoseTimestamp, backfill.timestamp)
        XCTAssertEqual(glucose.glucose, backfill.glucose)
        XCTAssertEqual(glucose.algorithmState, backfill.algorithmState)
        XCTAssertEqual(glucose.trend, backfill.trend)
    }

}
