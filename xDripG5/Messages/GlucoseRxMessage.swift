//
//  GlucoseRxMessage.swift
//  xDrip5
//
//  Created by Nathan Racklyeft on 11/23/15.
//  Copyright © 2015 Nathan Racklyeft. All rights reserved.
//

import Foundation

public protocol GlucoseRxMessage: TransmitterRxMessage {
    var glucose: UInt16 {
        get
        set
    }

}
