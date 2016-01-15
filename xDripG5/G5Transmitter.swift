//
//  G5Sensor.swift
//  xDripG5
//
//  Created by Dennis Gove on 1/12/16.
//  Copyright © 2016 Nathan Racklyeft. All rights reserved.
//

import Foundation

public class G5Transmitter: BluetoothManagerDelegate, Transmitter {

    public var transmitterId: String
    private var passiveModeEnabled: Bool

    private var transmitterDelegate: TransmitterDelegate?

    // Bluetoothy things
    private let bluetoothManager = BluetoothManager()
    private var operationQueue = dispatch_queue_create("com.loudnate.xDripG5.transmitterOperationQueue", DISPATCH_QUEUE_SERIAL)

    public init(transmitterId: String, passiveModeEnabled: Bool = false) {
        self.transmitterId = transmitterId
        self.passiveModeEnabled = passiveModeEnabled

        bluetoothManager.delegate = self
    }

    public var delegate: TransmitterDelegate? {
        get{
            return transmitterDelegate
        }
        set{
            transmitterDelegate = newValue
        }
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

    func bluetoothManager(manager: BluetoothManager, isReadyWithError error: NSError?) {
        if let error = error {
            self.delegate?.transmitter(self, didError: error)
            return
        }

        dispatch_async(operationQueue) {
            if self.passiveModeEnabled {
                do {
                    try self.listenToControl()
                } catch let error {
                    self.delegate?.transmitter(self, didError: error)
                }
            } else {
                do {
                    try self.authenticate()
                    try self.control()
                } catch let error {
                    manager.disconnect()

                    self.delegate?.transmitter(self, didError: error)
                }
            }
        }
    }


    // MARK: - Helpers

    private func authenticate() throws {
        if let data = try? bluetoothManager.readValueForCharacteristicAndWait(.Authentication),
            status = AuthStatusRxMessage(data: data) where status.authenticated == 1 && status.bonded == 1
        {
            NSLog("Transmitter already authenticated.")
        } else {
            do {
                try bluetoothManager.setNotifyEnabledAndWait(true, forCharacteristicUUID: .Authentication)
            } catch let error {
                throw TransmitterError.AuthenticationError("Error enabling notification: \(error)")
            }

            let authMessage = AuthRequestTxMessage()
            let data: NSData

            do {
                data = try bluetoothManager.writeValueAndWait(authMessage.data, forCharacteristicUUID: .Authentication, expectingFirstByte: AuthChallengeRxMessage.opcode)
            } catch let error {
                throw TransmitterError.AuthenticationError("Error writing transmitter challenge: \(error)")
            }

            guard let response = AuthChallengeRxMessage(data: data) else {
                throw TransmitterError.AuthenticationError("Unable to parse auth challenge: \(data)")
            }

            guard response.tokenHash == self.calculateHash(authMessage.singleUseToken) else {
                throw TransmitterError.AuthenticationError("Transmitter failed auth challenge")
            }

            if let challengeHash = self.calculateHash(response.challenge) {
                let data: NSData
                do {
                    data = try bluetoothManager.writeValueAndWait(AuthChallengeTxMessage(challengeHash: challengeHash).data, forCharacteristicUUID: .Authentication, expectingFirstByte: AuthStatusRxMessage.opcode)
                } catch let error {
                    throw TransmitterError.AuthenticationError("Error writing challenge response: \(error)")
                }

                guard let response = AuthStatusRxMessage(data: data) else {
                    throw TransmitterError.AuthenticationError("Unable to parse auth status: \(data)")
                }

                guard response.authenticated == 1 else {
                    throw TransmitterError.AuthenticationError("Transmitter rejected auth challenge")
                }

                if response.bonded != 0x1 {
                    do {
                        try bluetoothManager.writeValueAndWait(KeepAliveTxMessage(time: 25).data, forCharacteristicUUID: .Authentication)
                    } catch let error {
                        throw TransmitterError.AuthenticationError("Error writing keep-alive for bond: \(error)")
                    }

                    let data: NSData
                    do {
                        // Wait for the OS dialog to pop-up before continuing.
                        data = try bluetoothManager.writeValueAndWait(BondRequestTxMessage().data, forCharacteristicUUID: .Authentication, timeout: 15, expectingFirstByte: AuthStatusRxMessage.opcode)
                    } catch let error {
                        throw TransmitterError.AuthenticationError("Error writing bond request: \(error)")
                    }

                    guard let response = AuthStatusRxMessage(data: data) else {
                        throw TransmitterError.AuthenticationError("Unable to parse auth status: \(data)")
                    }

                    guard response.bonded == 0x1 else {
                        throw TransmitterError.AuthenticationError("Transmitter failed to bond")
                    }
                }
            }

            do {
                try bluetoothManager.setNotifyEnabledAndWait(false, forCharacteristicUUID: .Authentication)
            } catch let error {
                throw TransmitterError.AuthenticationError("Error disabling notification: \(error)")
            }
        }
    }

    private func control() throws {
        do {
            try bluetoothManager.setNotifyEnabledAndWait(true, forCharacteristicUUID: .Control)
        } catch let error {
            throw TransmitterError.ControlError("Error enabling notification: \(error)")
        }

        let glucoseData: NSData
        do {
            glucoseData = try bluetoothManager.writeValueAndWait(GlucoseTxMessage().data, forCharacteristicUUID: .Control, expectingFirstByte: G5GlucoseRxMessage.opcode)
        } catch let error {
            throw TransmitterError.ControlError("Error writing glucose request: \(error)")
        }

        guard let glucoseMessage = G5GlucoseRxMessage(data: glucoseData) else {
            throw TransmitterError.ControlError("Unable to parse glucose response: \(glucoseData)")
        }

        self.delegate?.transmitter(self, didReadGlucose: glucoseMessage)

        do {
            try bluetoothManager.setNotifyEnabledAndWait(false, forCharacteristicUUID: .Control)
            try bluetoothManager.writeValueAndWait(DisconnectTxMessage().data, forCharacteristicUUID: .Control)
        } catch {
        }
    }

    private func listenToControl() throws {
        do {
            try bluetoothManager.setNotifyEnabledAndWait(true, forCharacteristicUUID: .Control)
        } catch let error {
            throw TransmitterError.ControlError("Error enabling notification: \(error)")
        }

        let timeData: NSData
        do {
            timeData = try bluetoothManager.waitForCharacteristicValueUpdate(.Control, expectingFirstByte: TransmitterTimeRxMessage.opcode)
        } catch let error {
            throw TransmitterError.ControlError("Error waiting for time response: \(error)")
        }

        guard let timeMessage = TransmitterTimeRxMessage(data: timeData) else {
            throw TransmitterError.ControlError("Unable to parse time response: \(timeData)")
        }

        let glucoseData: NSData
        do {
            glucoseData = try bluetoothManager.waitForCharacteristicValueUpdate(.Control, expectingFirstByte: G5GlucoseRxMessage.opcode)
        } catch let error {
            throw TransmitterError.ControlError("Error waiting for glucose response: \(error)")
        }

        guard let glucoseMessage = G5GlucoseRxMessage(data: glucoseData) else {
            throw TransmitterError.ControlError("Unable to parse glucose response: \(glucoseData)")
        }

        self.delegate?.transmitter(self, didReadGlucose: glucoseMessage)
    }

    private var cryptKey: NSData? {
        return "00\(transmitterId)00\(transmitterId)".dataUsingEncoding(NSUTF8StringEncoding)
    }

    private func calculateHash(data: NSData) -> NSData? {
        guard data.length == 8, let key = cryptKey, outData = NSMutableData(length: 16) else {
            return nil
        }

        let doubleData = NSMutableData(data: data)
        doubleData.appendData(data)

        let status = CCCrypt(
            0, // kCCEncrypt
            0, // kCCAlgorithmAES
            0x0002, // kCCOptionECBMode
            key.bytes,
            key.length,
            nil,
            doubleData.bytes,
            doubleData.length,
            outData.mutableBytes,
            outData.length,
            nil
        )
        
        if status != 0 { // kCCSuccess
            return nil
        } else {
            return outData[0..<8]
        }
    }
}