//
//  Calibration.swift
//  xDripG5
//
//  Created by Paul Dickens on 17/03/2018.
//  Copyright © 2018 LoopKit Authors. All rights reserved.
//

import Foundation
import LoopAlgorithm


public struct Calibration {
    init?(calibrationMessage: CalibrationDataRxMessage, activationDate: Date) {
        guard calibrationMessage.glucose > 0 else {
            return nil
        }

        let unit = LoopUnit.milligramsPerDeciliter

        glucose = LoopQuantity(unit: unit, doubleValue: Double(calibrationMessage.glucose))
        date = activationDate.addingTimeInterval(TimeInterval(calibrationMessage.timestamp))
    }

    public let glucose: LoopQuantity
    public let date: Date
}
