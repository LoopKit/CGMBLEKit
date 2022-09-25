//
//  CGMBLEKitG7Plugin.swift
//  CGMBLEKitG7Plugin
//
//  Created by Pete Schwamb on 9/24/22.
//  Copyright © 2022 LoopKit Authors. All rights reserved.
//

import os.log
import LoopKitUI
import CGMBLEKit
import CGMBLEKitUI

class CGMBLEKitG7Plugin: NSObject, CGMManagerUIPlugin {
    private let log = OSLog(category: "CGMBLEKitG7Plugin")

    public var cgmManagerType: CGMManagerUI.Type? {
        return G7CGMManager.self
    }

    override init() {
        super.init()
        log.default("Instantiated")
    }
}
