//
//  BluetoothManager.swift
//  xDripG5
//
//  Created by Nathan Racklyeft on 10/1/15.
//  Copyright © 2015 Nathan Racklyeft. All rights reserved.
//

import CoreBluetooth
import Foundation
import os.log


protocol BluetoothManagerDelegate: class {

    /**
     Tells the delegate that the bluetooth manager has finished connecting to and discovering all required services of its peripheral, or that it failed to do so

     - parameter manager: The bluetooth manager
     - parameter error:   An error describing why bluetooth setup failed
     */
    func bluetoothManager(_ manager: BluetoothManager, isReadyWithError error: Error?)

    /**
     Asks the delegate whether the discovered or restored peripheral should be connected

     - parameter manager:    The bluetooth manager
     - parameter peripheral: The found peripheral

     - returns: True if the peripheral should connect
     */
    func bluetoothManager(_ manager: BluetoothManager, shouldConnectPeripheral peripheral: CBPeripheral) -> Bool

    /// Tells the delegate that the bluetooth manager received new data in the control characteristic.
    ///
    /// - parameter manager:                   The bluetooth manager
    /// - parameter didReceiveControlResponse: The data received on the control characteristic
    func bluetoothManager(_ manager: BluetoothManager, didReceiveControlResponse response: Data)
}


enum BluetoothManagerError: Error {
    case notReady
    case unknownCharacteristic
    case cbPeripheralError(Error)
    case timeout
}


private enum BluetoothOperationCondition {
    case notificationStateUpdate(characteristic: CBCharacteristic, enabled: Bool)
    case valueUpdate(characteristic: CBCharacteristic, firstByte: UInt8?)
    case writeUpdate(characteristic: CBCharacteristic)
}

extension BluetoothOperationCondition: Hashable {
    var hashValue: Int {
        switch self {
        case .notificationStateUpdate(characteristic: let characteristic, enabled: let enabled):
            return 1 ^ characteristic.hashValue ^ enabled.hashValue
        case .valueUpdate(characteristic: let characteristic, firstByte: let firstByte):
            return 2 ^ characteristic.hashValue ^ (firstByte?.hashValue ?? -1)
        case .writeUpdate(characteristic: let characteristic):
            return 3 ^ characteristic.hashValue
        }
    }
}

private func ==(lhs: BluetoothOperationCondition, rhs: BluetoothOperationCondition) -> Bool {
    return lhs.hashValue == rhs.hashValue
}


class BluetoothManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {

    var stayConnected = true

    weak var delegate: BluetoothManagerDelegate?

    private let log: OSLog

    private var manager: CBCentralManager! = nil

    private var peripheral: CBPeripheral? {
        didSet {
            if let oldValue = oldValue {
                oldValue.delegate = nil
            }

            if let newValue = peripheral {
                newValue.delegate = self
            }
        }
    }

    // MARK: - GCD Management

    private var managerQueue = DispatchQueue(label: "com.loudnate.xDripG5.bluetoothManagerQueue", qos: .userInitiated)

    override init() {
        log = OSLog(subsystem: Bundle(for: BluetoothManager.self).bundleIdentifier!, category: "BluetoothManager")

        super.init()

        manager = CBCentralManager(delegate: self, queue: managerQueue, options: [CBCentralManagerOptionRestoreIdentifierKey: "com.loudnate.xDripG5"])
    }

    // MARK: - Actions

    func scanForPeripheral() {
        guard manager.state == .poweredOn else {
            return
        }

        if let peripheralID = self.peripheral?.identifier, let peripheral = manager.retrievePeripherals(withIdentifiers: [peripheralID]).first {
            log.info("Re-connecting to known peripheral %{public}@", peripheral.identifier.uuidString)
            self.peripheral = peripheral
            self.manager.connect(peripheral, options: nil)
        } else if let peripheral = manager.retrieveConnectedPeripherals(withServices: [
            CBUUID(string: TransmitterServiceUUID.Advertisement.rawValue),
            CBUUID(string: TransmitterServiceUUID.CGMService.rawValue)
        ]).first, delegate == nil || delegate!.bluetoothManager(self, shouldConnectPeripheral: peripheral) {
            log.info("Found system-connected peripheral: %{public}@", peripheral.identifier.uuidString)
            self.peripheral = peripheral
            self.manager.connect(peripheral, options: nil)
        } else {
            log.info("Scanning for peripherals")
            manager.scanForPeripherals(withServices: [
                    CBUUID(string: TransmitterServiceUUID.Advertisement.rawValue)
                ],
                options: nil
            )
        }
    }

    func disconnect() {
        if manager.isScanning {
            manager.stopScan()
        }

        if let peripheral = peripheral {
            manager.cancelPeripheralConnection(peripheral)
        }
    }

    /**
    
     Persistent connections don't seem to work with the transmitter shutoff: The OS won't re-wake the
     app unless it's scanning.
     
     The sleep gives the transmitter time to shut down, but keeps the app running.

     */
    fileprivate func scanAfterDelay() {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.utility).async {
            Thread.sleep(forTimeInterval: 2)

            self.scanForPeripheral()
        }
    }

    deinit {
        stayConnected = false
        disconnect()
    }

    // MARK: - Operations

    /// The locking signal for the active operation
    private let operationLock = NSCondition()

    /// The required conditions for the operation to complete
    private var operationConditions: Set<BluetoothOperationCondition> = []

    /// Any error surfaced during the active operation
    private var operationError: Error?

    func readValueForCharacteristicAndWait(_ UUID: CGMServiceCharacteristicUUID, timeout: TimeInterval = 2, expectingFirstByte firstByte: UInt8? = nil) throws -> Data {
        guard manager.state == .poweredOn && operationConditions.isEmpty, let peripheral = peripheral else {
            throw BluetoothManagerError.notReady
        }

        guard let characteristic = getCharacteristicWithUUID(UUID) else {
            throw BluetoothManagerError.unknownCharacteristic
        }

        operationLock.lock()
        operationConditions.insert(.valueUpdate(characteristic: characteristic, firstByte: firstByte))

        peripheral.readValue(for: characteristic)

        let signaled = operationLock.wait(until: Date(timeIntervalSinceNow: timeout))

        defer {
            operationConditions = []
            operationError = nil
            operationLock.unlock()
        }

        if !signaled {
            throw BluetoothManagerError.timeout
        } else if let operationError = operationError {
            throw BluetoothManagerError.cbPeripheralError(operationError)
        }

        return characteristic.value ?? Data()
    }

    func setNotifyEnabledAndWait(_ enabled: Bool, forCharacteristicUUID UUID: CGMServiceCharacteristicUUID, timeout: TimeInterval = 2) throws {
        guard manager.state == .poweredOn && operationConditions.isEmpty, let peripheral = peripheral else {
            throw BluetoothManagerError.notReady
        }

        guard let characteristic = getCharacteristicWithUUID(UUID) else {
            throw BluetoothManagerError.unknownCharacteristic
        }

        operationLock.lock()
        operationConditions.insert(.notificationStateUpdate(characteristic: characteristic, enabled: enabled))

        peripheral.setNotifyValue(enabled, for: characteristic)

        let signaled = operationLock.wait(until: Date(timeIntervalSinceNow: timeout))

        defer {
            operationConditions = []
            operationError = nil
            operationLock.unlock()
        }

        if !signaled {
            throw BluetoothManagerError.timeout
        } else if let operationError = operationError {
            throw BluetoothManagerError.cbPeripheralError(operationError)
        }
    }

    func waitForCharacteristicValueUpdate(_ UUID: CGMServiceCharacteristicUUID, timeout: TimeInterval = 5, expectingFirstByte firstByte: UInt8? = nil) throws -> Data {
        guard manager.state == .poweredOn && operationConditions.isEmpty && peripheral != nil else {
            throw BluetoothManagerError.notReady
        }

        guard let characteristic = getCharacteristicWithUUID(UUID) , characteristic.isNotifying else {
            throw BluetoothManagerError.unknownCharacteristic
        }

        operationLock.lock()
        operationConditions.insert(.valueUpdate(characteristic: characteristic, firstByte: firstByte))

        let signaled = operationLock.wait(until: Date(timeIntervalSinceNow: timeout))

        defer {
            operationConditions = []
            operationError = nil
            operationLock.unlock()
        }

        if !signaled {
            throw BluetoothManagerError.timeout
        } else if let operationError = operationError {
            throw BluetoothManagerError.cbPeripheralError(operationError)
        }

        return characteristic.value ?? Data()
    }

    func writeValueAndWait(_ value: Data, forCharacteristicUUID UUID: CGMServiceCharacteristicUUID, timeout: TimeInterval = 2, expectingFirstByte firstByte: UInt8? = nil) throws -> Data {
        guard manager.state == .poweredOn && operationConditions.isEmpty, let peripheral = peripheral else {
            throw BluetoothManagerError.notReady
        }

        guard let characteristic = getCharacteristicWithUUID(UUID) else {
            throw BluetoothManagerError.unknownCharacteristic
        }

        operationLock.lock()
        operationConditions.insert(.writeUpdate(characteristic: characteristic))

        if characteristic.isNotifying {
            operationConditions.insert(.valueUpdate(characteristic: characteristic, firstByte: firstByte))
        }

        peripheral.writeValue(value, for: characteristic, type: .withResponse)

        let signaled = operationLock.wait(until: Date(timeIntervalSinceNow: timeout))

        defer {
            operationConditions = []
            operationError = nil
            operationLock.unlock()
        }

        if !signaled {
            throw BluetoothManagerError.timeout
        } else if let operationError = operationError {
            throw BluetoothManagerError.cbPeripheralError(operationError)
        }

        return characteristic.value ?? Data()
    }

    // MARK: - Accessors

    var isScanning: Bool {
        return manager.isScanning
    }

    private func getServiceWithUUID(_ UUID: TransmitterServiceUUID) -> CBService? {
        guard let services = peripheral?.services else {
            return nil
        }

        return services.itemWithUUIDString(UUID.rawValue)
    }

    private func getCharacteristicForServiceUUID(_ serviceUUID: TransmitterServiceUUID, withUUIDString UUIDString: String) -> CBCharacteristic? {
        guard let characteristics = getServiceWithUUID(serviceUUID)?.characteristics else {
            return nil
        }

        return characteristics.itemWithUUIDString(UUIDString)
    }

    private func getCharacteristicWithUUID(_ UUID: CGMServiceCharacteristicUUID) -> CBCharacteristic? {
        return getCharacteristicForServiceUUID(.CGMService, withUUIDString: UUID.rawValue)
    }

    // MARK: - CBCentralManagerDelegate

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            scanForPeripheral()
        case .resetting, .poweredOff, .unauthorized, .unknown, .unsupported:
            if central.isScanning {
                central.stopScan()
            }
        }
    }

    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        if let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
            for peripheral in peripherals {
                if delegate == nil || delegate!.bluetoothManager(self, shouldConnectPeripheral: peripheral) {
                    log.info("Restoring peripheral from state: %{public}@", peripheral.identifier.uuidString)
                    self.peripheral = peripheral
                }
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if delegate == nil || delegate!.bluetoothManager(self, shouldConnectPeripheral: peripheral) {
            self.peripheral = peripheral

            central.connect(peripheral, options: nil)

            central.stopScan()
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if central.isScanning {
            central.stopScan()
        }

        let knownServiceUUIDs = peripheral.services?.flatMap({ $0.uuid }) ?? []

        let servicesToDiscover = [
            CBUUID(string: TransmitterServiceUUID.CGMService.rawValue)
        ].filter({ !knownServiceUUIDs.contains($0) })

        if servicesToDiscover.count > 0 {
            log.info("Discovering services")
            peripheral.discoverServices(servicesToDiscover)
        } else {
            self.peripheral(peripheral, didDiscoverServices: nil)
        }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if stayConnected {
            scanAfterDelay()
        }
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if stayConnected {
            scanAfterDelay()
        }
    }

    // MARK: - CBPeripheralDelegate

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services ?? [] where service.uuid.uuidString == TransmitterServiceUUID.CGMService.rawValue {
            var characteristicsToDiscover = [CBUUID]()
            let knownCharacteristics = service.characteristics?.flatMap({ $0.uuid }) ?? []

            switch TransmitterServiceUUID(rawValue: service.uuid.uuidString) {
            case .CGMService?:
                characteristicsToDiscover = [
                    CBUUID(string: CGMServiceCharacteristicUUID.Communication.rawValue),
                    CBUUID(string: CGMServiceCharacteristicUUID.Authentication.rawValue),
                    CBUUID(string: CGMServiceCharacteristicUUID.Control.rawValue)
                ]
            case .ServiceB?:
                break
            default:
                break
            }

            characteristicsToDiscover = characteristicsToDiscover.filter({ !knownCharacteristics.contains($0) })

            if characteristicsToDiscover.count > 0 {
                log.info("Discovering characteristics")
                peripheral.discoverCharacteristics(characteristicsToDiscover, for: service)
            } else {
                self.peripheral(peripheral, didDiscoverCharacteristicsFor: service, error: nil)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            log.error("Error discovering characteristics: %{public}@", String(describing: error))
        }

        self.delegate?.bluetoothManager(self, isReadyWithError: error)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {

        operationLock.lock()

        if operationConditions.remove(.notificationStateUpdate(characteristic: characteristic, enabled: characteristic.isNotifying)) != nil {
            operationError = error

            if operationConditions.isEmpty {
                operationLock.broadcast()
            }
        }

        operationLock.unlock()
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        operationLock.lock()

        if operationConditions.remove(.valueUpdate(characteristic: characteristic, firstByte: characteristic.value?[0])) != nil ||
            operationConditions.remove(.valueUpdate(characteristic: characteristic, firstByte: nil)) != nil
        {
            operationError = error

            if operationConditions.isEmpty {
                operationLock.broadcast()
            }
        }

        operationLock.unlock()

        if let data = characteristic.value {
            delegate?.bluetoothManager(self, didReceiveControlResponse: data)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {

        operationLock.lock()

        if operationConditions.remove(.writeUpdate(characteristic: characteristic)) != nil {
            operationError = error

            if operationConditions.isEmpty {
                operationLock.broadcast()
            }
        }
        
        operationLock.unlock()
    }
}


private extension Array where Element: CBAttribute {

    func itemWithUUIDString(_ UUIDString: String) -> Element? {
        for attribute in self {
            if attribute.uuid.uuidString == UUIDString {
                return attribute
            }
        }

        return nil
    }

}
