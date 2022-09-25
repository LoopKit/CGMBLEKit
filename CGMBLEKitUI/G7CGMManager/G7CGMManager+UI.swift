//
//  G7CGMManager+UI.swift
//  CGMBLEKitUI
//
//  Created by Pete Schwamb on 9/24/22.
//  Copyright © 2022 LoopKit Authors. All rights reserved.
//

import Foundation
import CGMBLEKit
import LoopKitUI
import LoopKit

extension G7CGMManager: CGMManagerUI {
    public static var onboardingImage: UIImage? {
        return nil
    }

    public static func setupViewController(bluetoothProvider: BluetoothProvider, displayGlucoseUnitObservable: DisplayGlucoseUnitObservable, colorPalette: LoopUIColorPalette, allowDebugFeatures: Bool) -> SetupUIResult<CGMManagerViewController, CGMManagerUI> {

        let vc = G7UICoordinator(colorPalette: colorPalette, allowDebugFeatures: allowDebugFeatures)
        return .userInteractionRequired(vc)
    }

    public func settingsViewController(bluetoothProvider: BluetoothProvider, displayGlucoseUnitObservable: DisplayGlucoseUnitObservable, colorPalette: LoopUIColorPalette, allowDebugFeatures: Bool) ->CGMManagerViewController {

        return G7UICoordinator(cgmManager: self, colorPalette: colorPalette, allowDebugFeatures: allowDebugFeatures)
    }

    public var smallImage: UIImage? {
        UIImage(named: "g7", in: Bundle(for: TransmitterSetupViewController.self), compatibleWith: nil)!
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
