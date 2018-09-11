//
//  TransmitterManager+UI.swift
//  Loop
//
//  Copyright © 2018 LoopKit Authors. All rights reserved.
//

import LoopKit
import LoopKitUI
import HealthKit
import CGMBLEKit


extension G5CGMManager: CGMManagerUI {
    public static func setupViewController() -> (UIViewController & CGMManagerSetupViewController)? {
        let setupVC = TransmitterSetupViewController.instantiateFromStoryboard()
        setupVC.cgmManagerType = self
        return setupVC
    }

    public func settingsViewController(for glucoseUnit: HKUnit) -> UIViewController {
        return TransmitterSettingsViewController(cgmManager: self, glucoseUnit: .milligramsPerDeciliter)
    }

    public var smallImage: UIImage? {
        return nil
    }
}


extension G6CGMManager: CGMManagerUI {
    public static func setupViewController() -> (UIViewController & CGMManagerSetupViewController)? {
        let setupVC = TransmitterSetupViewController.instantiateFromStoryboard()
        setupVC.cgmManagerType = self
        return setupVC
    }

    public func settingsViewController(for glucoseUnit: HKUnit) -> UIViewController {
        return TransmitterSettingsViewController(cgmManager: self, glucoseUnit: .milligramsPerDeciliter)
    }

    public var smallImage: UIImage? {
        return nil
    }
}



class G5CGMManagerSetupViewController: UIViewController, CGMManagerSetupViewController {
    weak var setupDelegate: CGMManagerSetupViewControllerDelegate?

}
