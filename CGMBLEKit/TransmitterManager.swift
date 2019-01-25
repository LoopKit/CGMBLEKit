//
//  TransmitterManager.swift
//  Loop
//
//  Copyright © 2017 LoopKit Authors. All rights reserved.
//

import HealthKit
import LoopKit
import ShareClient
import os.log


public struct TransmitterManagerState: RawRepresentable, Equatable {
    public typealias RawValue = CGMManager.RawStateValue

    public static let version = 1

    public var transmitterID: String

    public var passiveModeEnabled: Bool = true

    public init(transmitterID: String) {
        self.transmitterID = transmitterID
    }

    public init?(rawValue: RawValue) {
        guard let transmitterID = rawValue["transmitterID"] as? String
        else {
            return nil
        }

        self.init(transmitterID: transmitterID)
    }

    public var rawValue: RawValue {
        return [
            "transmitterID": transmitterID
        ]
    }
}


public protocol TransmitterManagerObserver: class {
    func transmitterManagerDidUpdateLatestReading(_ manager: TransmitterManager)
}


public class TransmitterManager: TransmitterDelegate {
    private var state: TransmitterManagerState

    private let observers = Locked(NSHashTable<AnyObject>.weakObjects())

    public required init(state: TransmitterManagerState) {
        self.state = state
        self.transmitter = Transmitter(id: state.transmitterID, passiveModeEnabled: state.passiveModeEnabled)
        self.shareManager = ShareClientManager()

        self.transmitter.delegate = self
    }

    required convenience public init?(rawState: CGMManager.RawStateValue) {
        guard let state = TransmitterManagerState(rawValue: rawState) else {
            return nil
        }

        self.init(state: state)
    }

    public var rawState: CGMManager.RawStateValue {
        return state.rawValue
    }

    public let shouldSyncToRemoteService = false

    weak var delegate: CGMManagerDelegate? {
        didSet {
            shareManager.cgmManagerDelegate = delegate
        }
    }

    public let shareManager: ShareClientManager

    public let transmitter: Transmitter
    let log = OSLog(category: "TransmitterManager")

    public var providesBLEHeartbeat: Bool {
        return dataIsFresh
    }

    public var sensorState: SensorDisplayable? {
        let transmitterDate = latestReading?.readDate ?? .distantPast
        let shareDate = shareManager.latestBackfill?.startDate ?? .distantPast

        if transmitterDate >= shareDate {
            return latestReading
        } else {
            return shareManager.sensorState
        }
    }

    public var managedDataInterval: TimeInterval? {
        if transmitter.passiveModeEnabled {
            return .hours(3)
        }

        return shareManager.managedDataInterval
    }

    private(set) public var latestReading: Glucose? {
        get {
            return lockedLatestReading.value
        }
        set {
            lockedLatestReading.value = newValue
        }
    }
    private let lockedLatestReading: Locked<Glucose?> = Locked(nil)

    private var dataIsFresh: Bool {
        guard let latestGlucose = latestReading,
            latestGlucose.readDate > Date(timeIntervalSinceNow: .minutes(-4.5)) else {
            return false
        }

        return true
    }

    public func fetchNewDataIfNeeded(_ completion: @escaping (CGMResult) -> Void) {
        // If our last glucose was less than 4.5 minutes ago, don't fetch.
        guard !dataIsFresh else {
            completion(.noData)
            return
        }

        log.default("Fetching new glucose from Share because last reading is %{public}.1f minutes old", latestReading?.readDate.timeIntervalSinceNow.minutes ?? 0)

        shareManager.fetchNewDataIfNeeded(completion)
    }

    public var device: HKDevice? {
        return nil
    }

    public var debugDescription: String {
        return [
            "## \(String(describing: type(of: self)))",
            "latestReading: \(String(describing: latestReading))",
            "transmitter: \(String(reflecting: transmitter))",
            "dataIsFresh: \(dataIsFresh)",
            "providesBLEHeartbeat: \(providesBLEHeartbeat)",
            shareManager.debugDescription,
            "observers.count: \(observers.value.count)",
            ""
        ].joined(separator: "\n")
    }

    private func updateDelegate(with result: CGMResult) {
        if let manager = self as? CGMManager {
            delegate?.cgmManager(manager, didUpdateWith: result)
        }

        notifyObserversOfLatestReading()
    }

    // MARK: - TransmitterDelegate

    public func transmitter(_ transmitter: Transmitter, didError error: Error) {
        log.error("%{public}@: %{public}@", #function, String(describing: error))
        updateDelegate(with: .error(error))
    }

    public func transmitter(_ transmitter: Transmitter, didRead glucose: Glucose) {
        guard glucose != latestReading else {
            updateDelegate(with: .noData)
            return
        }

        latestReading = glucose

        guard glucose.state.hasReliableGlucose else {
            log.default("%{public}@: Unreliable glucose: %{public}@", #function, String(describing: glucose.state))
            updateDelegate(with: .error(CalibrationError.unreliableState(glucose.state)))
            return
        }
        
        guard let quantity = glucose.glucose else {
            updateDelegate(with: .noData)
            return
        }

        log.default("%{public}@: New glucose", #function)

        updateDelegate(with: .newData([
            NewGlucoseSample(
                date: glucose.readDate,
                quantity: quantity,
                isDisplayOnly: glucose.isDisplayOnly,
                syncIdentifier: glucose.syncIdentifier,
                device: device
            )
        ]))
    }

    public func transmitter(_ transmitter: Transmitter, didReadBackfill glucose: [Glucose]) {
        let samples = glucose.compactMap { (glucose) -> NewGlucoseSample? in
            guard glucose != latestReading, glucose.state.hasReliableGlucose, let quantity = glucose.glucose else {
                return nil
            }

            return NewGlucoseSample(
                date: glucose.readDate,
                quantity: quantity,
                isDisplayOnly: glucose.isDisplayOnly,
                syncIdentifier: glucose.syncIdentifier,
                device: device
            )
        }

        guard samples.count > 0 else {
            return
        }

        updateDelegate(with: .newData(samples))
    }

    public func transmitter(_ transmitter: Transmitter, didReadUnknownData data: Data) {
        log.error("Unknown sensor data: %{public}@", data.hexadecimalString)
        // This can be used for protocol discovery, but isn't necessary for normal operation
    }
}


// MARK: - Observer management
extension TransmitterManager {
    public func addObserver(_ observer: TransmitterManagerObserver) {
        _ = observers.mutate { (observerTable) in
            observerTable.add(observer as AnyObject)
        }
    }

    public func removeObserver(_ observer: TransmitterManagerObserver) {
        _ = observers.mutate { (observerTable) in
            observerTable.remove(observer as AnyObject)
        }
    }

    private func notifyObserversOfLatestReading() {
        let observers = self.observers.value.objectEnumerator()

        for observer in observers {
            if let observer = observer as? TransmitterManagerObserver {
                observer.transmitterManagerDidUpdateLatestReading(self)
            }
        }
    }
}


public class G5CGMManager: TransmitterManager, CGMManager {
    public static let managerIdentifier: String = "DexG5Transmitter"

    public static let localizedTitle = LocalizedString("Dexcom G5", comment: "CGM display title")

    public var appURL: URL? {
        return URL(string: "dexcomcgm://")
    }

    public var cgmManagerDelegate: CGMManagerDelegate? {
        get {
            return self.delegate
        }
        set {
            self.delegate = newValue
        }
    }

    public override var device: HKDevice? {
        return HKDevice(
            name: "CGMBLEKit",
            manufacturer: "Dexcom",
            model: "G5 Mobile",
            hardwareVersion: nil,
            firmwareVersion: nil,
            softwareVersion: String(CGMBLEKitVersionNumber),
            localIdentifier: nil,
            udiDeviceIdentifier: "00386270000002"
        )
    }
}


public class G6CGMManager: TransmitterManager, CGMManager {
    public static let managerIdentifier: String = "DexG6Transmitter"

    public static let localizedTitle = LocalizedString("Dexcom G6", comment: "CGM display title")

    public var appURL: URL? {
        return URL(string: "dexcomg6://")
    }

    public var cgmManagerDelegate: CGMManagerDelegate? {
        get {
            return self.delegate
        }
        set {
            self.delegate = newValue
        }
    }

    public override var device: HKDevice? {
        return HKDevice(
            name: "CGMBLEKit",
            manufacturer: "Dexcom",
            model: "G6",
            hardwareVersion: nil,
            firmwareVersion: nil,
            softwareVersion: String(CGMBLEKitVersionNumber),
            localIdentifier: nil,
            udiDeviceIdentifier: "00386270000385"
        )
    }
}


enum CalibrationError: Error {
    case unreliableState(CalibrationState)
}

extension CalibrationError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .unreliableState:
            return LocalizedString("Glucose data is unavailable", comment: "Error description for unreliable state")
        }
    }

    var failureReason: String? {
        switch self {
        case .unreliableState(let state):
            return state.localizedDescription
        }
    }
}

extension CalibrationState {
    public var localizedDescription: String {
        switch self {
        case .known(let state):
            switch state {
            case .needCalibration7, .needCalibration14, .needFirstInitialCalibration, .needSecondInitialCalibration, .calibrationError8, .calibrationError9, .calibrationError10, .calibrationError13:
                return LocalizedString("Sensor needs calibration", comment: "The description of sensor calibration state when sensor needs calibration.")
            case .ok:
                return LocalizedString("Sensor calibration is OK", comment: "The description of sensor calibration state when sensor calibration is ok.")
            case .stopped, .sensorFailure11, .sensorFailure12, .sessionFailure15, .sessionFailure16, .sessionFailure17:
                return LocalizedString("Sensor is stopped", comment: "The description of sensor calibration state when sensor sensor is stopped.")
            case .warmup, .questionMarks:
                return LocalizedString("Sensor is warming up", comment: "The description of sensor calibration state when sensor sensor is warming up.")
            }
        case .unknown(let rawValue):
            return String(format: LocalizedString("Sensor is in unknown state %1$d", comment: "The description of sensor calibration state when raw value is unknown. (1: missing data details)"), rawValue)
        }
    }
}
