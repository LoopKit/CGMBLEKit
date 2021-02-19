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
    public static func setupViewController(colorPalette: LoopUIColorPalette) -> SetupUIResult<UIViewController & CGMManagerCreateNotifying & CGMManagerOnboardNotifying & CompletionNotifying, CGMManagerUI> {
        let setupVC = TransmitterSetupViewController.instantiateFromStoryboard()
        setupVC.cgmManagerType = self
        return .userInteractionRequired(setupVC)
    }

    public func settingsViewController(for preferredGlucoseUnit: HKUnit, colorPalette: LoopUIColorPalette) -> (UIViewController & CGMManagerOnboardNotifying & PreferredGlucoseUnitObserver & CompletionNotifying) {
        let settings = TransmitterSettingsViewController(cgmManager: self, glucoseUnit: .milligramsPerDeciliter)
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
    public static func setupViewController(colorPalette: LoopUIColorPalette) -> SetupUIResult<UIViewController & CGMManagerCreateNotifying & CGMManagerOnboardNotifying & CompletionNotifying, CGMManagerUI> {
        let setupVC = TransmitterSetupViewController.instantiateFromStoryboard()
        setupVC.cgmManagerType = self
        return .userInteractionRequired(setupVC)
    }

    public func settingsViewController(for preferredGlucoseUnit: HKUnit, colorPalette: LoopUIColorPalette) -> (UIViewController & CGMManagerOnboardNotifying & PreferredGlucoseUnitObserver & CompletionNotifying) {
        let settings = TransmitterSettingsViewController(cgmManager: self, glucoseUnit: .milligramsPerDeciliter)
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
