//
//  CGMBLEKitG6Plugin.swift
//  CGMBLEKitG6Plugin
//
//  Created by Nathaniel Hamming on 2019-12-13.
//  Copyright © 2019 LoopKit Authors. All rights reserved.
//

import Foundation
import LoopKitUI
import CGMBLEKit
import CGMBLEKitUI
import os.log

class CGMBLEKitG6Plugin: NSObject, LoopUIPlugin {
    
    private let log = OSLog(category: "CGMBLEKitG6Plugin")
    
    public var pumpManagerType: PumpManagerUI.Type? {
        return nil
    }
    
    public var cgmManagerType: CGMManagerUI.Type? {
        return G6CGMManager.self
    }
    
    override init() {
        super.init()
        log.default("CGMBLEKitG6Plugin Instantiated")
    }
}
