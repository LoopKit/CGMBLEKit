//
//  G7CGMManager.swift
//  CGMBLEKit
//
//  Created by Pete Schwamb on 9/24/22.
//  Copyright © 2022 LoopKit Authors. All rights reserved.
//

import Foundation
import LoopKit
import os.log
import HealthKit


public class G7CGMManager: CGMManager {
    private let log = OSLog(category: "G7CGMManager")

    public var state: G7CGMManagerState {
        return lockedState.value
    }

    private func setState(_ changes: (_ state: inout G7CGMManagerState) -> Void) -> Void {
        return setStateWithResult(changes)
    }

    @discardableResult
    private func mutateState(_ changes: (_ state: inout G7CGMManagerState) -> Void) -> G7CGMManagerState {
        return setStateWithResult({ (state) -> G7CGMManagerState in
            changes(&state)
            return state
        })
    }

    private func setStateWithResult<ReturnType>(_ changes: (_ state: inout G7CGMManagerState) -> ReturnType) -> ReturnType {
        var oldValue: G7CGMManagerState!
        var returnType: ReturnType!
        let newValue = lockedState.mutate { (state) in
            oldValue = state
            returnType = changes(&state)
        }

        if oldValue != newValue {
            delegate.notify { delegate in
                delegate?.cgmManagerDidUpdateState(self)
                delegate?.cgmManager(self, didUpdate: self.cgmManagerStatus)
            }
        }

        return returnType
    }
    private let lockedState: Locked<G7CGMManagerState>

    public weak var cgmManagerDelegate: CGMManagerDelegate? {
        get {
            return delegate.delegate
        }
        set {
            delegate.delegate = newValue
        }
    }

    public var delegateQueue: DispatchQueue! {
        get {
            return delegate.queue
        }
        set {
            delegate.queue = newValue
        }
    }

    private let delegate = WeakSynchronizedDelegate<CGMManagerDelegate>()

    public var providesBLEHeartbeat: Bool = true

    public var managedDataInterval: TimeInterval? {
        return .hours(3)
    }

    public var shouldSyncToRemoteService = false

    public var glucoseDisplay: GlucoseDisplayable? {
        return latestReading
    }

    public var isScanning: Bool {
        return sensor.isScanning
    }

    public var sensorName: String? {
        return state.sensorID
    }

    private(set) public var latestReading: G7GlucoseMessage? {
        get {
            return lockedLatestReading.value
        }
        set {
            lockedLatestReading.value = newValue
        }
    }
    private let lockedLatestReading: Locked<G7GlucoseMessage?> = Locked(nil)

    public let sensor: G7Sensor

    public var cgmManagerStatus: LoopKit.CGMManagerStatus {
        return CGMManagerStatus(hasValidSensorSession: true, device: device)
    }

    public func fetchNewDataIfNeeded(_ completion: @escaping (LoopKit.CGMReadingResult) -> Void) {

        sensor.resumeScanning()

        completion(.noData)
    }

    public init() {
        lockedState = Locked(G7CGMManagerState())
        sensor = G7Sensor(sensorID: nil)
        sensor.delegate = self
    }

    public required init?(rawState: RawStateValue) {
        let state = G7CGMManagerState(rawValue: rawState)
        lockedState = Locked(state)
        sensor = G7Sensor(sensorID: state.sensorID)
        sensor.delegate = self
    }

    public var rawState: RawStateValue {
        return state.rawValue
    }

    public var debugDescription: String {
        let lines = [
            "## G7CGMManager",
            "sensorID: \(String(describing: state.sensorID))",
        ]
        return lines.joined(separator: "\n")
    }

    public func acknowledgeAlert(alertIdentifier: LoopKit.Alert.AlertIdentifier, completion: @escaping (Error?) -> Void) {
        completion(nil)
    }

    public func getSoundBaseURL() -> URL? { return nil }
    public func getSounds() -> [Alert.Sound] { return [] }

    public let managerIdentifier: String = "DexG7Transmitter"

    public let localizedTitle = LocalizedString("Dexcom G7", comment: "CGM display title")

    public let isOnboarded = true   // No distinction between created and onboarded

    public var appURL: URL? {
        return nil
    }

    public var device: HKDevice? {
        return HKDevice(
            name: "CGMBLEKit",
            manufacturer: "Dexcom",
            model: "G7",
            hardwareVersion: nil,
            firmwareVersion: nil,
            softwareVersion: String(CGMBLEKitVersionNumber),
            localIdentifier: nil,
            udiDeviceIdentifier: "00386270001863"
        )
    }

    func logDeviceCommunication(_ message: String, type: DeviceLogEntryType = .send) {
        self.cgmManagerDelegate?.deviceManager(self, logEventForDeviceIdentifier: state.sensorID, type: type, message: message, completion: nil)
    }

    private func updateDelegate(with result: CGMReadingResult) {
        delegateQueue?.async {
            self.cgmManagerDelegate?.cgmManager(self, hasNew: result)
        }
    }
}

extension G7CGMManager: G7SensorDelegate {
    public func sensor(_ sensor: G7Sensor, didDiscoverNewSensor name: String, activatedAt: Date) -> Bool {
        logDeviceCommunication("New sensor \(name) discovered, activated at \(activatedAt)", type: .connection)

        let shouldSwitchToNewSensor = true

        if shouldSwitchToNewSensor {
            mutateState { state in
                state.sensorID = name
                state.activatedAt = activatedAt
            }
        }

        return shouldSwitchToNewSensor
    }

    public func sensorDidConnect(_ sensor: G7Sensor) {
        logDeviceCommunication("Sensor \(String(describing: sensor.peripheralIdentifier)) did connect", type: .connection)
    }

    public func sensor(_ sensor: G7Sensor, didError error: Error) {
        logDeviceCommunication("Sensor error \(error)", type: .error)
    }

    public func sensor(_ sensor: G7Sensor, didRead glucose: G7GlucoseMessage) {
        logDeviceCommunication("Sensor didRead \(glucose)", type: .receive)

        guard glucose != latestReading else {
            updateDelegate(with: .noData)
            return
        }

        latestReading = glucose

        guard let activationDate = sensor.activationDate else {
            logDeviceCommunication("Unable to process sensor reading without activation date.", type: .error)
            return
        }


//        guard glucose.state.hasReliableGlucose else {
//            log.default("%{public}@: Unreliable glucose: %{public}@", #function, String(describing: glucose.state))
//            updateDelegate(with: .error(CalibrationError.unreliableState(glucose.state)))
//            return
//        }

//        guard let quantity = glucose.glucose else {
//            updateDelegate(with: .noData)
//            return
//        }

        let unit = HKUnit.milligramsPerDeciliter
        let quantity = HKQuantity(unit: unit, doubleValue: Double(min(max(glucose.glucose, GlucoseLimits.minimum), GlucoseLimits.maximum)))

        updateDelegate(with: .newData([
            NewGlucoseSample(
                date: activationDate.addingTimeInterval(TimeInterval(glucose.timestamp)),
                quantity: quantity,
                condition: .none,
                trend: .flat,
                trendRate: nil,
                isDisplayOnly: glucose.glucoseIsDisplayOnly,
                wasUserEntered: glucose.glucoseIsDisplayOnly,
                syncIdentifier: glucose.syncIdentifier,
                device: device
            )
        ]))

    }

    public func sensor(_ sensor: G7Sensor, didReadBackfill backfill: [G7BackfillMessage]) {
        log.default("didReadBackfill: %{public}@", String(describing: backfill))

        guard let activationDate = sensor.activationDate else {
            log.error("Unable to process backfill without activation date.")
            return
        }

        let unit = HKUnit.milligramsPerDeciliter

        let samples = backfill.map { msg in
            let quantity = HKQuantity(unit: unit, doubleValue: Double(min(max(msg.glucose, GlucoseLimits.minimum), GlucoseLimits.maximum)))

            return NewGlucoseSample(
                date: activationDate.addingTimeInterval(TimeInterval(msg.timestamp)),
                quantity: quantity,
                condition: .none,
                trend: .flat,
                trendRate: nil,
                isDisplayOnly: msg.glucoseIsDisplayOnly,
                wasUserEntered: msg.glucoseIsDisplayOnly,
                syncIdentifier: msg.syncIdentifier,
                device: device
            )
        }

        updateDelegate(with: .newData(samples))
    }
}

extension G7GlucoseMessage {
    public var syncIdentifier: String {
        return "\(timestamp)"
    }
}

extension G7BackfillMessage {
    public var syncIdentifier: String {
        return "\(timestamp)"
    }
}


extension G7GlucoseMessage: GlucoseDisplayable {
    public var isStateValid: Bool {
        return true
    }

    public var trendType: LoopKit.GlucoseTrend? {
        return nil
    }

    public var trendRate: HKQuantity? {
        return nil
    }

    public var isLocal: Bool {
        return true
    }

    public var glucoseRangeCategory: LoopKit.GlucoseRangeCategory? {
        if glucose < GlucoseLimits.minimum {
            return .belowRange
        } else if glucose > GlucoseLimits.maximum {
            return .aboveRange
        } else {
            return nil
        }
    }
}
