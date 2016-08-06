//
//  NSUserDefaults.swift
//  xDripG5
//
//  Created by Nathan Racklyeft on 11/24/15.
//  Copyright © 2015 Nathan Racklyeft. All rights reserved.
//

import Foundation


extension NSUserDefaults {
    var passiveModeEnabled: Bool {
        get {
            return boolForKey("passiveModeEnabled") ?? false
        }
        set {
            setBool(newValue, forKey: "passiveModeEnabled")
        }
    }

    var stayConnected: Bool {
        get {
            return boolForKey("stayConnected") ?? true
        }
        set {
            setBool(newValue, forKey: "stayConnected")
        }
    }

    var transmitterID: String {
        get {
            return stringForKey("transmitterID") ?? "500000"
        }
        set {
            setObject(newValue, forKey: "transmitterID")
        }
    }
}
