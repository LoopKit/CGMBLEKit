//
//  CalibrationDataRxMessageTests.swift
//  xDripG5
//
//  Created by Nate Racklyeft on 9/18/16.
//  Copyright © 2016 Nathan Racklyeft. All rights reserved.
//

import XCTest
@testable import xDripG5


class CalibrationDataRxMessageTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testMessage() {
        let data = Data(hexadecimalString: "33002b290090012900ae00800050e929001225")!
        XCTAssertNotNil(CalibrationDataRxMessage(data: data))
    }
    
}
