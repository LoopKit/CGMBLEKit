//
//  Calibration.swift
//  xDripG5
//
//  Created by Paul Dickens on 17/03/2018.
//  Copyright © 2018 LoopKit Authors. All rights reserved.
//

import Foundation
import HealthKit


public struct Calibration {
    init(calibrationDataMessage: CalibrationDataRxMessage, activationDate: Date) {
        let unit = HKUnit.milligramsPerDeciliter()

        glucose = HKQuantity(unit: unit, doubleValue: Double(calibrationDataMessage.glucose))
        date = activationDate.addingTimeInterval(TimeInterval(calibrationDataMessage.timestamp))
    }

    public let glucose: HKQuantity
    public let date: Date
}
