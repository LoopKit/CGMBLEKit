//
//  Transmitter.swift
//  xDripG5
//
//  Created by Nathan Racklyeft on 11/22/15.
//  Copyright © 2015 Nathan Racklyeft. All rights reserved.
//

import Foundation
import CoreBluetooth
import HealthKit
import os.log


public protocol TransmitterDelegate: class {
    func dequeuePendingCommand(for transmitter: Transmitter) -> Command?

    func transmitter(_ transmitter: Transmitter, didFail command: Command, with error: Error)

    func transmitter(_ transmitter: Transmitter, didComplete command: Command)

    func transmitter(_ transmitter: Transmitter, didError error: Error)

    func transmitter(_ transmitter: Transmitter, didRead glucose: Glucose)

    func transmitter(_ transmitter: Transmitter, didRead calibration: Calibration)

    func transmitter(_ transmitter: Transmitter, didReadUnknownData data: Data)
}


public enum TransmitterError: Error {
    case authenticationError(String)
    case controlError(String)
}


public final class Transmitter: BluetoothManagerDelegate {

    /// The ID of the transmitter to connect to
    public var ID: String {
        return id.id
    }

    private var id: TransmitterID

    /// The initial activation date of the transmitter
    public private(set) var activationDate: Date?

    private var lastTimeMessage: TransmitterTimeRxMessage?

    public var passiveModeEnabled: Bool

    public weak var delegate: TransmitterDelegate?

    private let log = OSLog(category: "Transmitter")

    private let bluetoothManager = BluetoothManager()

    private var delegateQueue = DispatchQueue(label: "com.loudnate.xDripG5.delegateQueue", qos: .utility)

    public init(id: String, passiveModeEnabled: Bool = false) {
        self.id = TransmitterID(id: id)
        self.passiveModeEnabled = passiveModeEnabled

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

    func bluetoothManager(_ manager: BluetoothManager, isReadyWithError error: Error?) {
        if let error = error {
            delegateQueue.async {
                self.delegate?.transmitter(self, didError: error)
            }
            return
        }

        manager.peripheralManager?.perform { (peripheral) in
            if self.passiveModeEnabled {
                do {
                    try peripheral.listenToControl()
                } catch let error {
                    self.delegateQueue.async {
                        self.delegate?.transmitter(self, didError: error)
                    }
                }
            } else {
                do {
                    let status = try peripheral.authenticate(id: self.id)

                    if status.bonded != 0x1 {
                        try peripheral.requestBond()

                        self.log.info("Bonding request sent. Waiting user to respond.")
                    }

                    try peripheral.enableNotify(shouldWaitForBond: status.bonded != 0x1)
                    defer {
                        peripheral.disconnect()
                    }

                    let timeMessage = try peripheral.readTimeMessage()

                    let activationDate = Date(timeIntervalSinceNow: -TimeInterval(timeMessage.currentTime))

                    while let command = self.delegate?.dequeuePendingCommand(for: self) {
                        do {
                            _ = try peripheral.sendCommand(command, activationDate: activationDate)
                            self.delegateQueue.async {
                                self.delegate?.transmitter(self, didComplete: command)
                            }
                        } catch let error {
                            self.delegateQueue.async {
                                self.delegate?.transmitter(self, didFail: command, with: error)
                            }
                        }
                    }

                    let glucose = try peripheral.readGlucose(timeMessage: timeMessage, activationDate: activationDate)
                    self.delegateQueue.async {
                        self.delegate?.transmitter(self, didRead: glucose)
                    }

                    let calibrationData = try peripheral.readCalibrationData(activationDate: activationDate)
                    self.delegateQueue.async {
                        self.delegate?.transmitter(self, didRead: calibrationData)
                    }
                } catch let error {
                    self.delegateQueue.async {
                        self.delegate?.transmitter(self, didError: error)
                    }
                }
            }
        }
    }

    func bluetoothManager(_ manager: BluetoothManager, shouldConnectPeripheral peripheral: CBPeripheral) -> Bool {
        /// The Dexcom G5 advertises a peripheral name of "DexcomXX"
        /// where "XX" is the last-two characters of the transmitter ID.
        if let name = peripheral.name, name.suffix(2) == id.id.suffix(2) {
            return true
        } else {
            self.log.info("Not connecting to peripheral: %{public}@", peripheral.name ?? String(describing: peripheral))
            return false
        }
    }

    func bluetoothManager(_ manager: BluetoothManager, didReceiveControlResponse response: Data) {
        guard passiveModeEnabled else { return }

        guard response.count > 0 else { return }

        switch Opcode(rawValue: response[0]) {
        case .glucoseRx?:
            if  let glucoseMessage = GlucoseRxMessage(data: response),
                let timeMessage = lastTimeMessage,
                let activationDate = activationDate
            {
                delegateQueue.async {
                    self.delegate?.transmitter(self, didRead: Glucose(glucoseMessage: glucoseMessage, timeMessage: timeMessage, activationDate: activationDate))
                }
            }
        case .transmitterTimeRx?:
            if let timeMessage = TransmitterTimeRxMessage(data: response) {
                self.activationDate = Date(timeIntervalSinceNow: -TimeInterval(timeMessage.currentTime))
                self.lastTimeMessage = timeMessage
                return
            }
        case .none:
            delegateQueue.async {
               self.delegate?.transmitter(self, didReadUnknownData: response)
            }
        default:
            // We ignore all other known opcodes
            break
        }
    }
}


struct TransmitterID {
    let id: String

    init(id: String) {
        self.id = id
    }

    private var cryptKey: Data? {
        return "00\(id)00\(id)".data(using: .utf8)
    }

    func computeHash(of data: Data) -> Data? {
        guard data.count == 8, let key = cryptKey else {
            return nil
        }

        var doubleData = Data(capacity: data.count * 2)
        doubleData.append(data)
        doubleData.append(data)

        guard let outData = try? AESCrypt.encryptData(doubleData, usingKey: key) else {
            return nil
        }

        return outData[0..<8]
    }
}


// MARK: - Helpers
fileprivate extension PeripheralManager {
    fileprivate func authenticate(id: TransmitterID) throws -> AuthChallengeRxMessage {
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

        guard challengeResponse.authenticated == 1 else {
            throw TransmitterError.authenticationError("Transmitter rejected auth challenge")
        }

        return challengeResponse
    }

    fileprivate func requestBond() throws {
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

    fileprivate func enableNotify(shouldWaitForBond: Bool = false) throws {
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

    fileprivate func readTimeMessage() throws -> TransmitterTimeRxMessage {
        do {
            return try writeMessage(TransmitterTimeTxMessage(), for: .control)
        } catch let error {
            throw TransmitterError.controlError("Error getting time: \(error)")
        }
    }

    fileprivate func sendCommand(_ command: Command, activationDate: Date) throws -> TransmitterRxMessage {
        switch command {
        case .startSensor(let date):
            let startTime = UInt32(date.timeIntervalSince(activationDate))
            let startTimeEpoch = UInt32(date.timeIntervalSince1970)

            do {
                return try writeMessage(SessionStartTxMessage(time: startTime, timeEpoch: startTimeEpoch), for: .control)
            } catch let error {
                throw TransmitterError.controlError("Error starting session: \(error)")
            }
        case .stopSensor(let date):
            let stopTime = UInt32(date.timeIntervalSince(activationDate))

            do {
                return try writeMessage(SessionStopTxMessage(time: stopTime), for: .control)
            } catch let error {
                throw TransmitterError.controlError("Error stopping session: \(error)")
            }
        case .calibrateSensor(let glucose, let date):
            let unit = HKUnit.milligramsPerDeciliter()
            let glucoseValue = UInt16(glucose.doubleValue(for: unit).rounded())
            let time = UInt32(date.timeIntervalSince(activationDate))

            do {
                return try writeMessage(CalibrateGlucoseTxMessage(time: time, glucose: glucoseValue), for: .control)
            } catch let error {
                throw TransmitterError.controlError("Error calibrating sensor: \(error)")
            }
        }

    }

    fileprivate func readGlucose(timeMessage: TransmitterTimeRxMessage, activationDate: Date) throws -> Glucose {
        let glucoseMessage: GlucoseRxMessage
        do {
            glucoseMessage = try writeMessage(GlucoseTxMessage(), for: .control)
        } catch let error {
            throw TransmitterError.controlError("Error getting glucose: \(error)")
        }

        // Update and notify
        return Glucose(glucoseMessage: glucoseMessage, timeMessage: timeMessage, activationDate: activationDate)
    }

    fileprivate func readCalibrationData(activationDate: Date) throws -> Calibration {
        let calibrationDataMessage: CalibrationDataRxMessage
        do {
            calibrationDataMessage = try writeMessage(CalibrationDataTxMessage(), for: .control)
        } catch let error {
            throw TransmitterError.controlError("Error getting calibration data: \(error)")
        }

        return Calibration(calibrationDataMessage: calibrationDataMessage, activationDate: activationDate)
    }

    fileprivate func disconnect() {
        do {
            try setNotifyValue(false, for: .control)
            try writeMessage(DisconnectTxMessage(), for: .control)
        } catch {
        }
    }

    fileprivate func listenToControl() throws {
        do {
            try setNotifyValue(true, for: .control)
        } catch let error {
            throw TransmitterError.controlError("Error enabling notification: \(error)")
        }
    }
}
