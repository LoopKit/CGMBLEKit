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

    func testG7MessageData() {
        let data = Data(hexadecimalString: "45a100009600060ffc")!
        let message = G7BackfillMessage(data: data)!

        XCTAssertEqual(150, message.glucose)
        XCTAssertEqual(41285, message.timestamp)
    }

}
