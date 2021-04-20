//
//  TransmitterManager+UI.swift
//  Loop
//
//  Copyright © 2018 LoopKit Authors. All rights reserved.
//

import SwiftUI
import LoopKit
import LoopKitUI
import HealthKit
import CGMBLEKit


extension G5CGMManager: CGMManagerUI {
    public static func setupViewController(bluetoothProvider: BluetoothProvider, displayGlucoseUnitObservable: DisplayGlucoseUnitObservable, colorPalette: LoopUIColorPalette) -> SetupUIResult<CGMManagerViewController, CGMManagerUI> {
        let setupVC = TransmitterSetupViewController.instantiateFromStoryboard()
        setupVC.cgmManagerType = self
        return .userInteractionRequired(setupVC)
    }

    public func settingsViewController(bluetoothProvider: BluetoothProvider, displayGlucoseUnitObservable: DisplayGlucoseUnitObservable, colorPalette: LoopUIColorPalette) ->CGMManagerViewController {
        let settings = TransmitterSettingsViewController(cgmManager: self, displayGlucoseUnitObservable: displayGlucoseUnitObservable)
        let nav = CGMManagerSettingsNavigationViewController(rootViewController: settings)
        return nav
    }

    public var smallImage: UIImage? {
        return nil
    }

    // TODO Placeholder.
    public var cgmStatusHighlight: DeviceStatusHighlight? {
        return nil
    }

    // TODO Placeholder.
    public var cgmStatusBadge: DeviceStatusBadge? {
        return nil
    }

    // TODO Placeholder.
    public var cgmLifecycleProgress: DeviceLifecycleProgress? {
        return nil
    }
}


extension G6CGMManager: CGMManagerUI {
    public static func setupViewController(bluetoothProvider: BluetoothProvider, displayGlucoseUnitObservable: DisplayGlucoseUnitObservable, colorPalette: LoopUIColorPalette) -> SetupUIResult<CGMManagerViewController, CGMManagerUI> {
        let setupVC = TransmitterSetupViewController.instantiateFromStoryboard()
        setupVC.cgmManagerType = self
        return .userInteractionRequired(setupVC)
    }

    public func settingsViewController(bluetoothProvider: BluetoothProvider, displayGlucoseUnitObservable: DisplayGlucoseUnitObservable, colorPalette: LoopUIColorPalette) ->CGMManagerViewController {
        let settings = TransmitterSettingsViewController(cgmManager: self, displayGlucoseUnitObservable: displayGlucoseUnitObservable)
        let nav = CGMManagerSettingsNavigationViewController(rootViewController: settings)
        return nav
    }

    public var smallImage: UIImage? {
        return nil
    }

    // TODO Placeholder.
    public var cgmStatusHighlight: DeviceStatusHighlight? {
        return nil
    }

    // TODO Placeholder.
    public var cgmStatusBadge: DeviceStatusBadge? {
        return nil
    }

    // TODO Placeholder.
    public var cgmLifecycleProgress: DeviceLifecycleProgress? {
        return nil
    }
}
