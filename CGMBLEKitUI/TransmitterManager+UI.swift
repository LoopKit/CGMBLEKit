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
    public static var onboardingImage: UIImage? {
        return nil
    }

    public static func setupViewController(bluetoothProvider: BluetoothProvider, displayGlucosePreference: DisplayGlucosePreference, colorPalette: LoopUIColorPalette, allowDebugFeatures: Bool, prefersToSkipUserInteraction: Bool = false) -> SetupUIResult<CGMManagerViewController, CGMManagerUI> {
        let setupVC = TransmitterSetupViewController.instantiateFromStoryboard()
        setupVC.cgmManagerType = self
        return .userInteractionRequired(setupVC)
    }

    public func settingsViewController(bluetoothProvider: BluetoothProvider, displayGlucosePreference: DisplayGlucosePreference, colorPalette: LoopUIColorPalette, allowDebugFeatures: Bool) ->CGMManagerViewController {
        let settings = TransmitterSettingsViewController(cgmManager: self, displayGlucosePreference: displayGlucosePreference)
        let nav = CGMManagerSettingsNavigationViewController(rootViewController: settings)
        return nav
    }

    public var smallImage: UIImage? {
        return nil
    }

    public var cgmStatusHighlight: DeviceStatusHighlight? {
        return TransmitterSessionStatus.highlight(for: latestReading)
    }

    // TODO Placeholder.
    public var cgmStatusBadge: DeviceStatusBadge? {
        return nil
    }

    public var cgmLifecycleProgress: DeviceLifecycleProgress? {
        // G5 has no Anubis variant — always 2 h warmup.
        return TransmitterSessionStatus.lifecycle(for: latestReading, isAnubis: false)
    }
}


extension G6CGMManager: CGMManagerUI {
    public static var onboardingImage: UIImage? {
        return nil
    }

    public static func setupViewController(bluetoothProvider: BluetoothProvider, displayGlucosePreference: DisplayGlucosePreference, colorPalette: LoopUIColorPalette, allowDebugFeatures: Bool, prefersToSkipUserInteraction: Bool = false) -> SetupUIResult<CGMManagerViewController, CGMManagerUI> {
        let setupVC = TransmitterSetupViewController.instantiateFromStoryboard()
        setupVC.cgmManagerType = self
        return .userInteractionRequired(setupVC)
    }

    public func settingsViewController(bluetoothProvider: BluetoothProvider, displayGlucosePreference: DisplayGlucosePreference, colorPalette: LoopUIColorPalette, allowDebugFeatures: Bool) ->CGMManagerViewController {
        let settings = TransmitterSettingsViewController(cgmManager: self, displayGlucosePreference: displayGlucosePreference)
        let nav = CGMManagerSettingsNavigationViewController(rootViewController: settings)
        return nav
    }

    public var smallImage: UIImage? {
        UIImage(named: "g6", in: Bundle(for: TransmitterSetupViewController.self), compatibleWith: nil)!
    }

    public var cgmStatusHighlight: DeviceStatusHighlight? {
        return TransmitterSessionStatus.highlight(for: latestReading)
    }

    // TODO Placeholder.
    public var cgmStatusBadge: DeviceStatusBadge? {
        return nil
    }

    public var cgmLifecycleProgress: DeviceLifecycleProgress? {
        return TransmitterSessionStatus.lifecycle(for: latestReading, isAnubis: isAnubis)
    }
}


/// Shared lifecycle + status-highlight derivation for both G5 and G6.
/// Both transmitters compute `sessionStartDate` / `sessionExpDate` on every
/// reading (`Glucose.swift`), so we don't need to hardcode a sensor lifetime
/// — the transmitter already knows. Sensor state (warmup, sensor failure,
/// calibration needed, session failure) comes from `Glucose.state`.
private enum TransmitterSessionStatus {
    /// Stock G5/G6 warmup window (2 h from `sessionStartDate`).
    static let standardWarmupDuration: TimeInterval = 2 * 60 * 60

    /// Anubis-modded G6 warmup window (50 min from `sessionStartDate`).
    static let anubisWarmupDuration: TimeInterval = 50 * 60

    static func lifecycle(for glucose: Glucose?, isAnubis: Bool) -> DeviceLifecycleProgress? {
        guard let glucose, let start = glucose.sessionStartDate else { return nil }

        // During warmup the session expiry is ~10 days out — using it as the
        // ring's denominator would render ~0% and feel broken. Switch the
        // ring's denominator to the actual warmup window (50 min for Anubis,
        // 2 h for stock) so the arc visibly fills as warmup completes.
        if case .known(.warmup) = glucose.state {
            let elapsed = Date().timeIntervalSince(start)
            let warmupDuration = isAnubis ? anubisWarmupDuration : standardWarmupDuration
            let fraction = max(0, min(1, elapsed / warmupDuration))
            return G5G6LifecycleProgress(percentComplete: fraction, progressState: .normalCGM)
        }

        // Sensor / session failure or stopped: timing is meaningless.
        if case let .known(state) = glucose.state, !state.exposesLifecycle {
            return nil
        }

        guard let end = glucose.sessionExpDate else { return nil }
        let total = end.timeIntervalSince(start)
        guard total > 0 else { return nil }
        let elapsed = Date().timeIntervalSince(start)
        let fraction = max(0, min(1, elapsed / total))
        let progressState: DeviceLifecycleProgressState
        if fraction >= 1.0 {
            progressState = .critical
        } else if elapsed >= total - 24 * 60 * 60 {
            progressState = .warning
        } else {
            progressState = .normalCGM
        }
        return G5G6LifecycleProgress(percentComplete: fraction, progressState: progressState)
    }

    static func highlight(for glucose: Glucose?) -> DeviceStatusHighlight? {
        guard let glucose else { return nil }

        // Calibration-state surface wins over time-based expiry — a warming-
        // up sensor hasn't reached expiry yet, and an explicit sensor /
        // session failure is the more useful signal even if expiry is also
        // in the past.
        if case let .known(state) = glucose.state, let highlight = state.statusHighlight {
            return highlight
        }

        // Time-based expiry fallback.
        if let end = glucose.sessionExpDate, Date() >= end {
            return G5G6StatusHighlight(
                localizedMessage: NSLocalizedString("Sensor Expired", comment: "Sensor expired status"),
                imageName: "exclamationmark.circle.fill",
                state: .critical
            )
        }
        return nil
    }
}

private extension CalibrationState.State {
    /// `false` for states where session timing isn't yet meaningful —
    /// warmup, sensor / session failure, fully stopped sensor.
    var exposesLifecycle: Bool {
        switch self {
        case .warmup,
             .stopped,
             .sensorFailure11,
             .sensorFailure12,
             .sessionFailure15,
             .sessionFailure16,
             .sessionFailure17:
            return false
        default:
            return true
        }
    }

    var statusHighlight: DeviceStatusHighlight? {
        switch self {
        case .warmup:
            return G5G6StatusHighlight(
                localizedMessage: NSLocalizedString("Warming Up", comment: "Sensor warmup status"),
                imageName: "hourglass",
                state: .warning
            )
        case .needFirstInitialCalibration,
             .needSecondInitialCalibration,
             .needCalibration7,
             .needCalibration14:
            return G5G6StatusHighlight(
                localizedMessage: NSLocalizedString("Calibration Needed", comment: "Sensor needs calibration"),
                imageName: "drop.fill",
                state: .warning
            )
        case .calibrationError8,
             .calibrationError9,
             .calibrationError10,
             .calibrationError13:
            return G5G6StatusHighlight(
                localizedMessage: NSLocalizedString("Calibration Error", comment: "Sensor calibration error"),
                imageName: "exclamationmark.circle",
                state: .warning
            )
        case .sensorFailure11,
             .sensorFailure12:
            return G5G6StatusHighlight(
                localizedMessage: NSLocalizedString("Sensor Failed", comment: "Sensor hardware failure"),
                imageName: "exclamationmark.triangle.fill",
                state: .critical
            )
        case .sessionFailure15,
             .sessionFailure16,
             .sessionFailure17:
            return G5G6StatusHighlight(
                localizedMessage: NSLocalizedString("Session Failed", comment: "Sensor session failed"),
                imageName: "exclamationmark.triangle.fill",
                state: .critical
            )
        case .stopped:
            return G5G6StatusHighlight(
                localizedMessage: NSLocalizedString("Sensor Stopped", comment: "Sensor session stopped"),
                imageName: "stop.circle",
                state: .critical
            )
        case .questionMarks:
            return G5G6StatusHighlight(
                localizedMessage: NSLocalizedString("Signal Problem", comment: "Sensor signal problem"),
                imageName: "questionmark.circle",
                state: .warning
            )
        case .ok:
            return nil
        }
    }
}

private struct G5G6LifecycleProgress: DeviceLifecycleProgress {
    let percentComplete: Double
    let progressState: DeviceLifecycleProgressState
}

private struct G5G6StatusHighlight: DeviceStatusHighlight {
    let localizedMessage: String
    let imageName: String
    let state: DeviceStatusHighlightState
}
