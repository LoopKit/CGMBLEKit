//
//  G7SettingsViewModel.swift
//  CGMBLEKitUI
//
//  Created by Pete Schwamb on 10/4/22.
//  Copyright © 2022 LoopKit Authors. All rights reserved.
//

import Foundation
import CGMBLEKit
import LoopKit

class G7SettingsViewModel: ObservableObject {
    @Published var scanning: Bool = false
    @Published var sensorName: String?

    private var cgmManager: G7CGMManager

    init(cgmManager: G7CGMManager) {
        self.cgmManager = cgmManager
        updateValues()

        self.cgmManager.addStatusObserver(self, queue: DispatchQueue.main)
    }

    func updateValues() {
        scanning = cgmManager.isScanning
        sensorName = cgmManager.sensorName
    }
}

extension G7SettingsViewModel: CGMManagerStatusObserver {
    func cgmManager(_ manager: LoopKit.CGMManager, didUpdate status: LoopKit.CGMManagerStatus) {
        <#code#>
    }
}
