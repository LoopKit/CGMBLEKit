//
//  GlucoseBackfillMessageTests.swift
//  xDripG5Tests
//
//  Copyright © 2018 LoopKit Authors. All rights reserved.
//

import XCTest
@testable import CGMBLEKit

class GlucoseBackfillMessageTests: XCTestCase {

    func testTxMessage() {
        let message = GlucoseBackfillTxMessage(byte1: 5, byte2: 2, identifier: 0, startTime: 5439415, endTime: 5440614) // 20 minutes

        XCTAssertEqual(Data(hexadecimalString: "50050200b7ff5200660453000000000000007138")!, message.data)
    }

    func testRxMessage() {
        let message = GlucoseBackfillRxMessage(data: Data(hexadecimalString: "51000100b7ff52006604530032000000e6cb9805")!)!

        XCTAssertEqual(.ok, TransmitterStatus(rawValue: message.status))
        XCTAssertEqual(1, message.backfillStatus)
        XCTAssertEqual(0, message.identifier)
        XCTAssertEqual(5439415, message.startTime)
        XCTAssertEqual(5440614, message.endTime)
        XCTAssertEqual(50, message.bufferLength)
        XCTAssertEqual(0xcbe6, message.bufferCRC)

        var buffer = GlucoseBackfillFrameBuffer(identifier: message.identifier)
        buffer.append(Data(hexadecimalString: "0100bc460000b7ff52008b0006eee30053008500")!)
        buffer.append(Data(hexadecimalString: "020006eb0f025300800006ee3a0353007e0006f5")!)
        buffer.append(Data(hexadecimalString: "030066045300790006f8")!)

        XCTAssertEqual(Int(message.bufferLength), buffer.count)
        XCTAssertEqual(message.bufferCRC, buffer.crc16)

        let messages = buffer.glucose
        
        XCTAssertEqual(139, messages[0].glucose)
        XCTAssertEqual(5439415, messages[0].timestamp)
        XCTAssertEqual(.known(.ok), CalibrationState(rawValue: messages[0].state))
        XCTAssertEqual(-18, messages[0].trend)

        XCTAssertEqual(133, messages[1].glucose)
        XCTAssertEqual(5439715, messages[1].timestamp)
        XCTAssertEqual(.known(.ok), CalibrationState(rawValue: messages[1].state))
        XCTAssertEqual(-21, messages[1].trend)

        XCTAssertEqual(128, messages[2].glucose)
        XCTAssertEqual(5440015, messages[2].timestamp)
        XCTAssertEqual(.known(.ok), CalibrationState(rawValue: messages[2].state))
        XCTAssertEqual(-18, messages[2].trend)

        XCTAssertEqual(126, messages[3].glucose)
        XCTAssertEqual(5440314, messages[3].timestamp)
        XCTAssertEqual(.known(.ok), CalibrationState(rawValue: messages[3].state))
        XCTAssertEqual(-11, messages[3].trend)

        XCTAssertEqual(121, messages[4].glucose)
        XCTAssertEqual(5440614, messages[4].timestamp)
        XCTAssertEqual(.known(.ok), CalibrationState(rawValue: messages[4].state))
        XCTAssertEqual(-08, messages[4].trend)
    }
}
