//
//  BluetoothManager.swift
//  xDripG5
//
//  Created by Nathan Racklyeft on 10/1/15.
//  Copyright © 2015 Nathan Racklyeft. All rights reserved.
//

import CoreBluetooth
import UIKit


protocol BluetoothManagerDelegate: class {
    func bluetoothManager(manager: BluetoothManager, isReadyWithError error: NSError?)
}


enum BluetoothManagerError: ErrorType {
    case NotReady
    case UnknownCharacteristic
    case CBPeripheralError(NSError)
    case Timeout
}


private struct OperationCondition: OptionSetType {
    let rawValue: Int

    init(rawValue: Int) {
        self.rawValue = rawValue
    }

    static let NotificationStateUpdate = OperationCondition(rawValue: 0b1)
    static let ValueUpdate = OperationCondition(rawValue: 0b10)
    static let WriteUpdate = OperationCondition(rawValue: 0b100)
}


class BluetoothManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {

    private var manager: CBCentralManager! = nil

    weak var delegate: BluetoothManagerDelegate?

    private var peripheral: CBPeripheral?

    // MARK: - GCD Management

    private var managerQueue = dispatch_queue_create("com.loudnate.xDripG5.bluetoothManagerQueue", DISPATCH_QUEUE_SERIAL)

    override init() {
        super.init()

        manager = CBCentralManager(delegate: self, queue: managerQueue, options: [CBCentralManagerOptionRestoreIdentifierKey: "com.loudnate.xDripG5"])
    }

    // MARK: - Actions

    func scanForPeripheral() {
        manager.scanForPeripheralsWithServices(
            [
                CBUUID(string: TransmitterServiceUUID.Advertisement.rawValue)
            ],
            options: nil
        )

        if let peripheral = self.peripheral {
            self.manager.connectPeripheral(peripheral, options: nil)
        }
    }

    func disconnect() {
        if let peripheral = peripheral {
            manager.cancelPeripheralConnection(peripheral)
        }
    }

    /**
    
     Persistent connections don't seem to work with the transmitter shutoff: The OS won't re-wake the
     app unless it's scanning.
     
     The sleep gives the transmitter time to shut down, but keeps the app running.

     */
    private func scanAfterDelay() {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
            NSThread.sleepForTimeInterval(2)

            self.scanForPeripheral()
        }
    }

    // MARK: - Operations

    /// The locking signal for the active operation
    private let operationLock = NSCondition()

    /// The required conditions for the operation to complete
    private var operationConditions: OperationCondition = []

    /// Any error surfaced during the active operation
    private var operationError: NSError?


    func setNotifyEnabledAndWait(enabled: Bool, forCharacteristicUUID UUID: CGMServiceCharacteristicUUID, timeout: NSTimeInterval = 2) throws {
        guard manager.state == .PoweredOn && operationConditions.isEmpty, let peripheral = peripheral else {
            throw BluetoothManagerError.NotReady
        }

        guard let characteristic = getCharacteristicWithUUID(UUID) else {
            throw BluetoothManagerError.UnknownCharacteristic
        }

        operationLock.lock()
        operationConditions.insert(.NotificationStateUpdate)

        peripheral.setNotifyValue(enabled, forCharacteristic: characteristic)

        let signaled = operationLock.waitUntilDate(NSDate(timeIntervalSinceNow: timeout))

        defer {
            operationConditions = []
            operationError = nil
            operationLock.unlock()
        }

        if !signaled {
            throw BluetoothManagerError.Timeout
        } else if let operationError = operationError {
            throw BluetoothManagerError.CBPeripheralError(operationError)
        }
    }

    func writeValueAndWait(value: NSData, forCharacteristicUUID UUID: CGMServiceCharacteristicUUID, timeout: NSTimeInterval = 2) throws -> NSData {
        guard manager.state == .PoweredOn && operationConditions.isEmpty, let peripheral = peripheral else {
            throw BluetoothManagerError.NotReady
        }

        guard let characteristic = getCharacteristicWithUUID(UUID) where characteristic.properties.contains(.Write) else {
            throw BluetoothManagerError.UnknownCharacteristic
        }

        operationLock.lock()

        operationConditions.insert(.WriteUpdate)

        if characteristic.isNotifying {
            operationConditions.insert(.ValueUpdate)
        }

        peripheral.writeValue(value, forCharacteristic: characteristic, type: .WithResponse)

        let signaled = operationLock.waitUntilDate(NSDate(timeIntervalSinceNow: timeout))

        defer {
            operationConditions = []
            operationError = nil
            operationLock.unlock()
        }

        if !signaled {
            throw BluetoothManagerError.Timeout
        } else if let operationError = operationError {
            throw BluetoothManagerError.CBPeripheralError(operationError)
        }

        return characteristic.value ?? NSData()
    }

    // MARK: - Accessors

    private func getServiceWithUUID(UUID: TransmitterServiceUUID) -> CBService? {
        guard let services = peripheral?.services else {
            return nil
        }

        return services.itemWithUUIDString(UUID.rawValue)
    }

    private func getCharacteristicForServiceUUID(serviceUUID: TransmitterServiceUUID, withUUIDString UUIDString: String) -> CBCharacteristic? {
        guard let characteristics = getServiceWithUUID(serviceUUID)?.characteristics else {
            return nil
        }

        return characteristics.itemWithUUIDString(UUIDString)
    }

    func getCharacteristicWithUUID(UUID: CGMServiceCharacteristicUUID) -> CBCharacteristic? {
        return getCharacteristicForServiceUUID(.CGMService, withUUIDString: UUID.rawValue)
    }

    // MARK: - CBCentralManagerDelegate

    func centralManagerDidUpdateState(central: CBCentralManager) {
        switch central.state {
        case .PoweredOn:
            if let peripheral = peripheral {
                central.connectPeripheral(peripheral, options: nil)
            } else {
                scanForPeripheral()
            }
        case .Resetting, .PoweredOff, .Unauthorized, .Unknown, .Unsupported:
            central.stopScan()
        }
    }

    func centralManager(central: CBCentralManager, willRestoreState dict: [String : AnyObject]) {
        if peripheral == nil, let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
            for peripheral in peripherals {

                self.peripheral = peripheral
                peripheral.delegate = self
            }
        }
    }

    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {

        self.peripheral = peripheral
        peripheral.delegate = self

        central.connectPeripheral(peripheral, options: nil)

        central.stopScan()
    }

    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        central.stopScan()

        let knownServiceUUIDs = peripheral.services?.flatMap({ $0.UUID }) ?? []

        let servicesToDiscover = [
            CBUUID(string: TransmitterServiceUUID.CGMService.rawValue)
        ].filter({ !knownServiceUUIDs.contains($0) })

        if servicesToDiscover.count > 0 {
            peripheral.discoverServices(servicesToDiscover)
        } else {
            self.peripheral(peripheral, didDiscoverServices: nil)
        }
    }

    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        scanAfterDelay()
    }

    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        scanAfterDelay()
    }

    // MARK: - CBPeripheralDelegate

    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        for service in peripheral.services ?? [] {
            var characteristicsToDiscover = [CBUUID]()
            let knownCharacteristics = service.characteristics?.flatMap({ $0.UUID }) ?? []

            switch TransmitterServiceUUID(rawValue: service.UUID.UUIDString) {
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
                peripheral.discoverCharacteristics(characteristicsToDiscover, forService: service)
            } else {
                self.peripheral(peripheral, didDiscoverCharacteristicsForService: service, error: nil)
            }
        }
    }

    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        self.delegate?.bluetoothManager(self, isReadyWithError: error)
    }

    func peripheral(peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?) {

        operationLock.lock()

        if operationConditions.remove(.NotificationStateUpdate) != nil {
            operationError = error

            if operationConditions.isEmpty {
                operationLock.broadcast()
            }
        }

        operationLock.unlock()
    }

    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {

        operationLock.lock()

        if operationConditions.remove(.ValueUpdate) != nil {
            operationError = error

            if operationConditions.isEmpty {
                operationLock.broadcast()
            }
        }

        operationLock.unlock()
    }

    func peripheral(peripheral: CBPeripheral, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {

        self.operationLock.lock()

        if operationConditions.remove(.WriteUpdate) != nil {
            operationError = error

            if operationConditions.isEmpty {
                operationLock.broadcast()
            }
        }
        
        self.operationLock.unlock()
    }
}


private extension Array where Element: CBAttribute {

    func itemWithUUIDString(UUIDString: String) -> Element? {
        for attribute in self {
            if attribute.UUID.UUIDString == UUIDString {
                return attribute
            }
        }

        return nil
    }

}
