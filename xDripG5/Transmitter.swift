//
//  Transmitter.swift
//  xDripG5
//
//  Created by Nathan Racklyeft on 11/22/15.
//  Copyright © 2015 Nathan Racklyeft. All rights reserved.
//

import Foundation


protocol TransmitterDelegate: class {

    func transmitter(transmitter: Transmitter, didReadGlucose glucose: GlucoseRxMessage)

    func transmitter(transmitter: Transmitter, didError error: ErrorType)
}


enum TransmitterError: ErrorType {
    case AuthenticationError
}


class Transmitter: BluetoothManagerDelegate {
    let ID: String

    var startTimeInterval: NSTimeInterval?

    weak var delegate: TransmitterDelegate?

    private let bluetoothManager = BluetoothManager()

    private var operationQueue = dispatch_queue_create("com.loudnate.xDripG5.transmitterOperationQueue", DISPATCH_QUEUE_SERIAL)

    init(ID: String, startTimeInterval: NSTimeInterval?) {
        self.ID = ID
        self.startTimeInterval = startTimeInterval

        bluetoothManager.delegate = self
    }

    // MARK: - BluetoothManagerDelegate

    func bluetoothManager(manager: BluetoothManager, isReadyWithError error: NSError?) {
        if let error = error {
            self.delegate?.transmitter(self, didError: error)
            return
        }

        dispatch_async(operationQueue) {
            do {
                try self.authenticate()

                try manager.setNotifyEnabledAndWait(true, forCharacteristicUUID: .Control)

                if let data = try? manager.writeValueAndWait(TransmitterTimeTxMessage().data, forCharacteristicUUID: .Control),
                    message = TransmitterTimeRxMessage(data: data)
                {
                    self.startTimeInterval = NSDate().timeIntervalSince1970 - NSTimeInterval(message.currentTime)
                }

                if let data = try? manager.writeValueAndWait(GlucoseTxMessage().data, forCharacteristicUUID: .Control),
                    message = GlucoseRxMessage(data: data)
                {
                    self.delegate?.transmitter(self, didReadGlucose: message)
                }

                try manager.setNotifyEnabledAndWait(false, forCharacteristicUUID: .Control)

                try manager.writeValueAndWait(DisconnectTxMessage().data, forCharacteristicUUID: .Control)
            } catch let error {
                manager.disconnect()

                self.delegate?.transmitter(self, didError: error)
            }
        }
    }

    // MARK: - Helpers

    func authenticate() throws {
        try bluetoothManager.setNotifyEnabledAndWait(true, forCharacteristicUUID: .Authentication)
        let authMessage = AuthRequestTxMessage()

        if let
            data = try? bluetoothManager.writeValueAndWait(authMessage.data, forCharacteristicUUID: .Authentication),
            response = AuthChallengeRxMessage(data: data)
        {
            if response.tokenHash == self.calculateHash(authMessage.singleUseToken),
                let challengeHash = self.calculateHash(response.challenge)
            {
                if let data = try? bluetoothManager.writeValueAndWait(AuthChallengeTxMessage(challengeHash: challengeHash).data, forCharacteristicUUID: .Authentication),
                    response = AuthStatusRxMessage(data: data)
                {
                    if response.bonded != 0x1 {
                        try bluetoothManager.writeValueAndWait(KeepAliveTxMessage(time: 25).data, forCharacteristicUUID: .Authentication)

                        // Wait for the OS dialog to pop-up before continuing.
                        try bluetoothManager.writeValueAndWait(BondRequestTxMessage().data, forCharacteristicUUID: .Authentication, timeout: 15)
                    }
                }
            } else {
                throw TransmitterError.AuthenticationError
            }
        }

        try bluetoothManager.setNotifyEnabledAndWait(false, forCharacteristicUUID: .Authentication)
    }

    private var cryptKey: NSData? {
        return "00\(ID)00\(ID)".dataUsingEncoding(NSUTF8StringEncoding)
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