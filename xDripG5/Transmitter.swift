//
//  Transmitter.swift
//  xDripG5
//
//  Created by Nathan Racklyeft on 11/22/15.
//  Copyright © 2015 Nathan Racklyeft. All rights reserved.
//

import Foundation

public protocol TransmitterDelegate: class {
    func transmitter(transmitter: Transmitter, didReadGlucose glucose: GlucoseRxMessage)
    func transmitter(transmitter: Transmitter, didError error: ErrorType)
}

public enum TransmitterError: ErrorType {
    case AuthenticationError(String)
    case ControlError(String)
}

public protocol Transmitter: class {

    // Id of transmitter
    var transmitterId: String {
        get
    }

    var delegate: TransmitterDelegate? {
        get
        set
    }


    // getter to know if the transmitter is scanning for values
    var isScanning: Bool {
        get
    }

    // getter/setter to know if transmitter should stay connected when the app is inactive
    var stayConnected: Bool {
        get
        set
    }

    // Stop scanning for values
    func stopScanning()

    // Resume (or start) scanning for values
    func resumeScanning()

}
