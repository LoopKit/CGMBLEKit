//
//  Glucose.swift
//  xDripG5
//
//  Created by Nate Racklyeft on 8/6/16.
//  Copyright © 2016 Nathan Racklyeft. All rights reserved.
//

import Foundation
import HealthKit


public struct Glucose {
    public let glucoseMessage: GlucoseRxMessage
    let timeMessage: TransmitterTimeRxMessage

    init(glucoseMessage: GlucoseRxMessage, timeMessage: TransmitterTimeRxMessage, activationDate: Date) {
        self.glucoseMessage = glucoseMessage
        self.timeMessage = timeMessage

        status = TransmitterStatus(rawValue: glucoseMessage.status)
        state = CalibrationState(rawValue: glucoseMessage.state)
        sessionStartDate = activationDate.addingTimeInterval(TimeInterval(timeMessage.sessionStartTime))
        readDate = activationDate.addingTimeInterval(TimeInterval(glucoseMessage.timestamp))
    }

    // MARK: - Transmitter Info
    public let status: TransmitterStatus
    public let sessionStartDate: Date

    // MARK: - Glucose Info
    public let state: CalibrationState
    public let readDate: Date

    public var isDisplayOnly: Bool {
        return glucoseMessage.glucoseIsDisplayOnly
    }

    public var glucose: HKQuantity? {
        guard state.hasReliableGlucose else {
            return nil
        }

        let unit = HKUnit.milligramsPerDeciliter()

        return HKQuantity(unit: unit, doubleValue: Double(glucoseMessage.glucose))
    }

    public var trend: Int {
        return Int(glucoseMessage.trend)
    }
}


extension Glucose: Equatable { }


public func ==(lhs: Glucose, rhs: Glucose) -> Bool {
    return lhs.glucoseMessage == rhs.glucoseMessage && lhs.timeMessage == rhs.timeMessage
}
