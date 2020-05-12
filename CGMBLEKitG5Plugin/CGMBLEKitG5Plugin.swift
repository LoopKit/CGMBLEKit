//
//  CGMBLEKitG5Plugin.swift
//  CGMBLEKitG5Plugin
//
//  Created by Nathaniel Hamming on 2019-12-19.
//  Copyright © 2019 LoopKit Authors. All rights reserved.
//

import Foundation
import LoopKitUI
import CGMBLEKit
import CGMBLEKitUI
import os.log

class CGMBLEKitG5Plugin: NSObject, LoopUIPlugin {
    
    private let log = OSLog(category: "CGMBLEKitG5Plugin")
    
    public var pumpManagerType: PumpManagerUI.Type? {
        return nil
    }
    
    public var cgmManagerType: CGMManagerUI.Type? {
        return G5CGMManager.self
    }
    
    override init() {
        super.init()
        log.default("CGMBLEKitG5Plugin Instantiated")
    }
}
