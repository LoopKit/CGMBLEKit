//
//  SensorIssueTests.swift
//  CGMBLEKitTests
//
//  Copyright © 2026 LoopKit Authors. All rights reserved.
//

import XCTest
@testable import CGMBLEKit

class SensorIssueTests: XCTestCase {

    func testEachStateIsReportedOnceUntilGlucoseIsReliable() {
        var state = TransmitterManagerState(transmitterID: "8G1234")
        let readings: [CalibrationState.State] = [.warmup, .warmup, .ok, .questionMarks, .questionMarks, .needCalibration7, .warmup]

        let issues = readings.compactMap { state.newSensorIssue(for: .known($0)) }

        XCTAssertEqual(issues, ["warmup", "questionMarks", "warmup"])
        XCTAssertEqual(state.reportedSensorIssue, "warmup")
    }

    func testReportedIssueSurvivesARelaunch() {
        var state = TransmitterManagerState(transmitterID: "8G1234")
        XCTAssertEqual(state.newSensorIssue(for: .known(.sensorFailure11)), "sensorFailure11")

        var restored = TransmitterManagerState(rawValue: state.rawValue)!

        XCTAssertEqual(restored.reportedSensorIssue, "sensorFailure11")
        XCTAssertNil(restored.newSensorIssue(for: .known(.sensorFailure11)))
    }

    func testFailureStates() {
        XCTAssertTrue(CalibrationState.known(.sessionFailure16).sensorFailed)
        XCTAssertFalse(CalibrationState.known(.warmup).sensorFailed)
        XCTAssertFalse(CalibrationState.unknown(99).sensorFailed)
    }
}
