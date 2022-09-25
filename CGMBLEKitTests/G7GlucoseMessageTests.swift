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

        XCTAssertEqual(156, message.glucose)
        XCTAssertEqual(83890, message.timestamp)
    }

}
