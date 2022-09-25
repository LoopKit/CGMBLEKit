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

    public var deviceName: String?

    public var cgmManagerDelegate: LoopKit.CGMManagerDelegate?

    public var providesBLEHeartbeat: Bool = true

    public var managedDataInterval: TimeInterval? {
        return .hours(3)
    }

    public var shouldSyncToRemoteService = false

    public var glucoseDisplay: GlucoseDisplayable? {
        return latestReading
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



    public var cgmManagerStatus: LoopKit.CGMManagerStatus {
        return CGMManagerStatus(hasValidSensorSession: false, device: device)
    }

    public var delegateQueue: DispatchQueue!

    public func fetchNewDataIfNeeded(_ completion: @escaping (LoopKit.CGMReadingResult) -> Void) {
        completion(.noData)
    }

    public init() {
    }

    public required init?(rawState: RawStateValue) {

    }

    public var rawState: RawStateValue {
        return [:]
    }

    public var debugDescription: String {
        let lines = [
            "## G7CGMManager",
            "deviceName: \(String(describing: deviceName))",
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
        self.cgmManagerDelegate?.deviceManager(self, logEventForDeviceIdentifier: deviceName, type: type, message: message, completion: nil)
    }
}


