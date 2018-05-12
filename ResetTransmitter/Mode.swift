//
//  Mode.swift
//  ResetTransmitter
//
//  Created by Paul Dickens on 12/5/18.
//  Copyright © 2018 LoopKit Authors. All rights reserved.
//

import Foundation


enum Mode: Int, CustomStringConvertible {
    case restart
    case reset

    static let count = 2

    var description: String {
        switch self {
        case .restart:
            return NSLocalizedString("Restart Sensor", comment: "Title of action to restart sensor")
        case .reset:
            return NSLocalizedString("Reset Transmitter", comment: "Title of action to reset transmitter")
        }
    }

    var alertTitle: String {
        switch self {
        case .restart:
            return NSLocalizedString("Are you sure you want to restart this transmitter?", comment: "Title of the restart confirmation sheet")
        case .reset:
            return NSLocalizedString("Are you sure you want to reset this transmitter?", comment: "Title of the reset confirmation sheet")
        }
    }

    var alertMessage: String {
        return NSLocalizedString("It will take up to 10 minutes to complete.", comment: "Message of the reset confirmation sheet")
    }

    var buttonTitle: String {
        switch self {
        case .restart:
            return NSLocalizedString("Restart", comment: "Restart button title")
        case .reset:
            return NSLocalizedString("Reset", comment: "Reset button title")
        }
    }

    var blurb: String {
        switch self {
        case .restart:
            return NSLocalizedString("This tool can restart a sensor session nearing its expiration date, without the two hour warmup period.\nRestarting is only supported for active sessions of more than two hours duration.\nThe user accepts responsibility for ensuring that the sensor was inserted more than two hours prior to restart.\nUse at your own risk.", comment: "Restart informative text")
        case .reset:
            return NSLocalizedString("This tool can reset the clock on a transmitter that has reached its expiration date, allowing new sensor sessions to again be started.\nThis may have unintended consequences for data services, such as Clarity and Share, especially when using a reset transmitter with the same account.\nResetting cannot be undone.\nUse at your own risk.", comment: "Reset informative text")
        }
    }
}
