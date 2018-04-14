//
//  PeripheralManagerError.swift
//  xDripG5
//
//  Copyright © 2017 LoopKit Authors. All rights reserved.
//

import CoreBluetooth


enum PeripheralManagerError: Error {
    case cbPeripheralError(Error)
    case notReady
    case timeout
    case unknownCharacteristic
}


extension PeripheralManagerError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .cbPeripheralError(let error):
            return error.localizedDescription
        case .notReady:
            return NSLocalizedString("Peripheral isnʼt connected", comment: "Not ready error description")
        case .timeout:
            return NSLocalizedString("Peripheral did not respond in time", comment: "Timeout error description")
        case .unknownCharacteristic:
            return NSLocalizedString("Unknown characteristic", comment: "Error description")
        }
    }

    var failureReason: String? {
        switch self {
        case .cbPeripheralError(let error as NSError):
            return error.localizedFailureReason
        default:
            return errorDescription
        }
    }
}
