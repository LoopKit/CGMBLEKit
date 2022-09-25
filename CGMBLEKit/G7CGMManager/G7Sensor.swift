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

    func sensor(_ sensor: G7Sensor, didReadUnknownData data: Data)
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

    private let log = OSLog(category: "Transmitter")

    private let bluetoothManager = BluetoothManager()

    private let delegateQueue = DispatchQueue(label: "com.loudnate.CGMBLEKit.delegateQueue", qos: .unspecified)

    private let sensorName: String

    public init(sensorName: String) {
        self.sensorName = sensorName
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
        if let name = peripheral.name, name.hasPrefix("DXCM"), name.suffix(2) == sensorName.suffix(2) {
            return true
        } else {
            self.log.info("Not connecting to peripheral: %{public}@", peripheral.name ?? String(describing: peripheral))
            return false
        }
    }

    func bluetoothManager(_ manager: BluetoothManager, peripheralManager: PeripheralManager, didReceiveControlResponse response: Data) {

        guard response.count > 0 else { return }

        log.debug("Received control response: %{public}@", response.hexadecimalString)

        switch G7Opcode(rawValue: response[0]) {
        case .glucoseTx?:
            if let glucoseMessage = G7GlucoseMessage(data: response)
            {
                activationDate = Date().addingTimeInterval(-TimeInterval(glucoseMessage.timestamp))
                delegateQueue.async {
                    self.delegate?.sensor(self, didRead: glucoseMessage)
                }
                peripheralManager.perform { (peripheral) in
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
        guard response.count == 0 else {
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
    func authenticate(id: TransmitterID) throws -> AuthChallengeRxMessage {
        let authMessage = AuthRequestTxMessage()

        do {
            try writeMessage(authMessage, for: .authentication)
        } catch let error {
            throw TransmitterError.authenticationError("Error writing transmitter challenge: \(error)")
        }

        let authResponse: AuthRequestRxMessage
        do {
            authResponse = try readMessage(for: .authentication)
        } catch let error {
            throw TransmitterError.authenticationError("Unable to parse auth challenge: \(error)")
        }

        guard authResponse.tokenHash == id.computeHash(of: authMessage.singleUseToken) else {
            throw TransmitterError.authenticationError("Transmitter failed auth challenge")
        }

        guard let challengeHash = id.computeHash(of: authResponse.challenge) else {
            throw TransmitterError.authenticationError("Failed to compute challenge hash for transmitter ID")
        }

        do {
            try writeMessage(AuthChallengeTxMessage(challengeHash: challengeHash), for: .authentication)
        } catch let error {
            throw TransmitterError.authenticationError("Error writing challenge response: \(error)")
        }

        let challengeResponse: AuthChallengeRxMessage
        do {
            challengeResponse = try readMessage(for: .authentication)
        } catch let error {
            throw TransmitterError.authenticationError("Unable to parse auth status: \(error)")
        }

        guard challengeResponse.isAuthenticated else {
            throw TransmitterError.authenticationError("Transmitter rejected auth challenge")
        }

        return challengeResponse
    }

    func requestBond() throws {
        do {
            try writeMessage(KeepAliveTxMessage(time: 25), for: .authentication)
        } catch let error {
            throw TransmitterError.authenticationError("Error writing keep-alive for bond: \(error)")
        }

        do {
            try writeMessage(BondRequestTxMessage(), for: .authentication)
        } catch let error {
            throw TransmitterError.authenticationError("Error writing bond request: \(error)")
        }
    }

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

    func readTimeMessage() throws -> TransmitterTimeRxMessage {
        do {
            return try writeMessage(TransmitterTimeTxMessage(), for: .control)
        } catch let error {
            throw TransmitterError.controlError("Error getting time: \(error)")
        }
    }

    /// - Throws: TransmitterError.controlError
    func sendCommand(_ command: Command, activationDate: Date) throws -> TransmitterRxMessage {
        do {
            switch command {
            case .startSensor(let date):
                let startTime = UInt32(date.timeIntervalSince(activationDate))
                let secondsSince1970 = UInt32(date.timeIntervalSince1970)
                return try writeMessage(SessionStartTxMessage(startTime: startTime, secondsSince1970: secondsSince1970), for: .control)
            case .stopSensor(let date):
                let stopTime = UInt32(date.timeIntervalSince(activationDate))
                return try writeMessage(SessionStopTxMessage(stopTime: stopTime), for: .control)
            case .calibrateSensor(let glucose, let date):
                let glucoseValue = UInt16(glucose.doubleValue(for: .milligramsPerDeciliter).rounded())
                let time = UInt32(date.timeIntervalSince(activationDate))
                return try writeMessage(CalibrateGlucoseTxMessage(time: time, glucose: glucoseValue), for: .control)
            case .resetTransmitter:
                return try writeMessage(ResetTxMessage(), for: .control)
            }
        } catch let error {
            throw TransmitterError.controlError("Error during \(command): \(error)")
        }
    }

    func readGlucose() throws -> GlucoseRxMessage {
        do {
            return try writeMessage(GlucoseTxMessage(), for: .control)
        } catch let error {
            throw TransmitterError.controlError("Error getting glucose: \(error)")
        }
    }

    func readCalibrationData() throws -> CalibrationDataRxMessage {
        do {
            return try writeMessage(CalibrationDataTxMessage(), for: .control)
        } catch let error {
            throw TransmitterError.controlError("Error getting calibration data: \(error)")
        }
    }

    func disconnect() {
        do {
            try setNotifyValue(false, for: .control)
            try writeMessage(DisconnectTxMessage(), for: .control)
        } catch {
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
