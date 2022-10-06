//
//  G7Sensor.swift
//  CGMBLEKit
//
//  Created by Pete Schwamb on 9/24/22.
//  Copyright © 2022 LoopKit Authors. All rights reserved.
//

import Foundation
import CoreBluetooth
import HealthKit
import os.log


public protocol G7SensorDelegate: AnyObject {
    func sensorDidConnect(_ transmitter: G7Sensor)

    func sensor(_ sensor: G7Sensor, didError error: Error)

    func sensor(_ sensor: G7Sensor, didRead glucose: G7GlucoseMessage)

    func sensor(_ sensor: G7Sensor, didReadBackfill backfill: [G7BackfillMessage])

    // If this returns true, then start following this sensor
    func sensor(_ sensor: G7Sensor, didDiscoverNewSensor name: String, activatedAt: Date) -> Bool
}

public enum G7SensorError: Error {
    case authenticationError(String)
    case controlError(String)
    case observationError(String)
}

extension G7SensorError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .authenticationError(let description):
            return description
        case .controlError(let description):
            return description
        case .observationError(let description):
            return description
        }
    }
}


public final class G7Sensor: BluetoothManagerDelegate {

    public weak var delegate: G7SensorDelegate?

    public weak var commandSource: TransmitterCommandSource?

    // MARK: - Passive observation state, confined to `bluetoothManager.managerQueue`

    /// The initial activation date of the sensor
    var activationDate: Date?

    /// The last-observed calibration message
    private var lastCalibrationMessage: CalibrationDataRxMessage?

    /// The backfill data buffer
    private var backfillBuffer: [G7BackfillMessage] = []

    // MARK: -

    private let log = OSLog(category: "G7Sensor")

    private let bluetoothManager = BluetoothManager()

    private let delegateQueue = DispatchQueue(label: "com.loudnate.CGMBLEKit.delegateQueue", qos: .unspecified)

    private var sensorID: String?

    public func setSensorId(_ newId: String) {
        self.sensorID = newId
    }

    public init(sensorID: String?) {
        self.sensorID = sensorID
        bluetoothManager.delegate = self
    }

    public func resumeScanning() {
        if stayConnected {
            bluetoothManager.scanForPeripheral()
        }
    }

    public func stopScanning() {
        bluetoothManager.disconnect()
    }

    public var isScanning: Bool {
        return bluetoothManager.isScanning
    }

    public var peripheralIdentifier: UUID? {
        get {
            return bluetoothManager.peripheralIdentifier
        }
        set {
            bluetoothManager.peripheralIdentifier = newValue
        }
    }

    public var stayConnected: Bool {
        get {
            return bluetoothManager.stayConnected
        }
        set {
            bluetoothManager.stayConnected = newValue

            if newValue {
                bluetoothManager.scanForPeripheral()
            }
        }
    }

    // MARK: - BluetoothManagerDelegate

    func bluetoothManager(_ manager: BluetoothManager, peripheralManager: PeripheralManager, isReadyWithError error: Error?) {
        if let error = error {
            delegateQueue.async {
                self.delegate?.sensor(self, didError: error)
            }
            return
        }

        delegateQueue.async {
            self.delegate?.sensorDidConnect(self)
        }

        peripheralManager.perform { (peripheral) in
            self.log.debug("Listening for authentication responses in passive mode")
            do {
                try peripheral.listenToCharacteristic(.authentication)
            } catch let error {
                self.delegateQueue.async {
                    self.delegate?.sensor(self, didError: error)
                }
            }
        }
    }

    func bluetoothManager(_ manager: BluetoothManager, shouldConnectPeripheral peripheral: CBPeripheral) -> Bool {

        /// The Dexcom G7 advertises a peripheral name of "DXCMxx"
        if let name = peripheral.name, name.hasPrefix("DXCM") {
            // If we're following this name or if we're scanning, connect
            if let sensorName = sensorID, name.suffix(2) == sensorName.suffix(2) {
                return true
            } else if sensorID == nil {
                return true
            }
        }
        self.log.info("Not connecting to peripheral: %{public}@", peripheral.name ?? String(describing: peripheral))
        return false
    }

    func handleGlucoseMessage(message: G7GlucoseMessage, peripheralManager: PeripheralManager) {
        activationDate = Date().addingTimeInterval(-TimeInterval(message.glucoseTimestamp))
        peripheralManager.perform { (peripheral) in
            self.log.debug("Listening for backfill responses")
            // Subscribe to backfill updates
            do {
                try peripheral.listenToCharacteristic(.backfill)
            } catch let error {
                self.log.error("Error trying to enable notifications on backfill characteristic: %{public}@", String(describing: error))
                self.delegateQueue.async {
                    self.delegate?.sensor(self, didError: error)
                }
            }
        }
        if sensorID == nil, let name = peripheralManager.peripheral.name, let activationDate = activationDate  {
            delegateQueue.async {
                guard let delegate = self.delegate else {
                    return
                }

                if delegate.sensor(self, didDiscoverNewSensor: name, activatedAt: activationDate) {
                    self.sensorID = name
                    self.activationDate = activationDate
                    self.delegate?.sensor(self, didRead: message)
                }
            }
        } else if sensorID != nil {
            delegateQueue.async {
                self.delegate?.sensor(self, didRead: message)
            }
        } else {
            self.log.error("Dropping unhandled glucose message: %{public}@", String(describing: message))
        }
    }

    func bluetoothManager(_ manager: BluetoothManager, peripheralManager: PeripheralManager, didReceiveControlResponse response: Data) {

        guard response.count > 0 else { return }

        log.debug("Received control response: %{public}@", response.hexadecimalString)

        switch G7Opcode(rawValue: response[0]) {
        case .glucoseTx?:
            if let glucoseMessage = G7GlucoseMessage(data: response) {
                handleGlucoseMessage(message: glucoseMessage, peripheralManager: peripheralManager)
            } else {
                delegateQueue.async {
                    self.delegate?.sensor(self, didError: G7SensorError.observationError("Unable to handle glucose control response"))
                }
            }
        case .backfillFinished:
            if backfillBuffer.count > 0 {
                delegateQueue.async {
                    self.delegate?.sensor(self, didReadBackfill: self.backfillBuffer)
                    self.backfillBuffer = []
                }
            }
        default:
            // We ignore all other known opcodes
            break
        }
    }

    func bluetoothManager(_ manager: BluetoothManager, didReceiveBackfillResponse response: Data) {

        log.debug("Received backfill response: %{public}@", response.hexadecimalString)

        guard response.count == 9 else {
            return
        }

        if let msg = G7BackfillMessage(data: response) {
            backfillBuffer.append(msg)
        }
    }

    func bluetoothManager(_ manager: BluetoothManager, peripheralManager: PeripheralManager, didReceiveAuthenticationResponse response: Data) {

        if let message = AuthChallengeRxMessage(data: response), message.isBonded, message.isAuthenticated {
            self.log.debug("Observed authenticated session. enabling notifications for control characteristic.")
            peripheralManager.perform { (peripheral) in
                // Stopping updates from authentication simultaneously with Dexcom's app causes CoreBluetooth to get into a weird state.
                /*
                do {
                    try peripheral.stopListeningToCharacteristic(.authentication)
                } catch let error {
                    self.log.error("Error trying to disable notifications on authentication characteristic: %{public}@", String(describing: error))
                }
                */

                do {
                    try peripheral.listenToCharacteristic(.control)
                } catch let error {
                    self.log.error("Error trying to enable notifications on control characteristic: %{public}@", String(describing: error))
                    self.delegateQueue.async {
                        self.delegate?.sensor(self, didError: error)
                    }
                }
            }
        } else {
            self.log.debug("Ignoring authentication response: %{public}@", response.hexadecimalString)
        }
    }
}


// MARK: - Helpers
fileprivate extension PeripheralManager {

    func enableNotify(shouldWaitForBond: Bool = false) throws {
        do {
            if shouldWaitForBond {
                try setNotifyValue(true, for: .control, timeout: 15)
            } else {
                try setNotifyValue(true, for: .control)
            }
        } catch let error {
            throw TransmitterError.controlError("Error enabling notification: \(error)")
        }
    }

    func listenToCharacteristic(_ characteristic: CGMServiceCharacteristicUUID) throws {
        do {
            try setNotifyValue(true, for: characteristic)
        } catch let error {
            throw TransmitterError.controlError("Error enabling notification for \(characteristic): \(error)")
        }
    }

    func stopListeningToCharacteristic(_ characteristic: CGMServiceCharacteristicUUID) throws {
        do {
            try setNotifyValue(false, for: characteristic)
        } catch let error {
            throw TransmitterError.controlError("Error disabling notification for \(characteristic): \(error)")
        }
    }
}
