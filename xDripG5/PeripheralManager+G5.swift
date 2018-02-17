//
//  PeripheralManager+G5.swift
//  xDripG5
//
//  Copyright © 2017 LoopKit Authors. All rights reserved.
//

import CoreBluetooth


extension PeripheralManager {
    func setNotifyValue(_ enabled: Bool,
        for characteristicUUID: CGMServiceCharacteristicUUID,
        timeout: TimeInterval = 2) throws
    {
        guard let characteristic = peripheral.getCharacteristicWithUUID(characteristicUUID) else {
            throw PeripheralManagerError.unknownCharacteristic
        }

        try setNotifyValue(enabled, for: characteristic, timeout: timeout)
    }

    func readValue(
        for characteristicUUID: CGMServiceCharacteristicUUID,
        timeout: TimeInterval = 2,
        expectingFirstByte firstByte: UInt8? = nil) throws -> Data
    {
        guard let characteristic = peripheral.getCharacteristicWithUUID(characteristicUUID) else {
            throw PeripheralManagerError.unknownCharacteristic
        }

        try runCommand(timeout: timeout) {
            addCondition(.makeValueUpdate(characteristic: characteristic, matchingFirstByte: firstByte))

            peripheral.readValue(for: characteristic)
        }

        guard let value = characteristic.value else {
            // TODO: This is an "unknown value" issue, not a timeout
            throw PeripheralManagerError.timeout
        }

        return value
    }

    func writeValue(_ value: Data,
        for characteristicUUID: CGMServiceCharacteristicUUID,
        type: CBCharacteristicWriteType = .withResponse,
        timeout: TimeInterval = 2,
        expectingFirstByte firstByte: UInt8? = nil) throws -> Data
    {
        guard let characteristic = peripheral.getCharacteristicWithUUID(characteristicUUID) else {
            throw PeripheralManagerError.unknownCharacteristic
        }

        try runCommand(timeout: timeout) {
            if case .withResponse = type {
                addCondition(.write(characteristic: characteristic))
            }

            if characteristic.isNotifying {
                addCondition(.makeValueUpdate(characteristic: characteristic, matchingFirstByte: firstByte))
            }

            peripheral.writeValue(value, for: characteristic, type: type)
        }

        let value = characteristic.value

        guard !characteristic.isNotifying || value != nil else {
            // TODO: This is an "unknown value" issue, not a timeout
            throw PeripheralManagerError.timeout
        }

        return value ?? Data()
    }
}


fileprivate extension PeripheralManager.CommandCondition {
    static func makeValueUpdate(characteristic: CBCharacteristic, matchingFirstByte firstByte: UInt8?) -> PeripheralManager.CommandCondition {
        return .valueUpdate(characteristic: characteristic, matching: { value in
            if let firstByte = firstByte {
                if let value = value, value.count > 0, value[0] == firstByte {
                    return true
                } else {
                    return false
                }
            } else { // No condition on response
                return true
            }
        })
    }
}


fileprivate extension CBPeripheral {
    func getServiceWithUUID(_ uuid: TransmitterServiceUUID) -> CBService? {
        return services?.itemWithUUIDString(uuid.rawValue)
    }

    func getCharacteristicForServiceUUID(_ serviceUUID: TransmitterServiceUUID, withUUIDString UUIDString: String) -> CBCharacteristic? {
        guard let characteristics = getServiceWithUUID(serviceUUID)?.characteristics else {
            return nil
        }

        return characteristics.itemWithUUIDString(UUIDString)
    }

    func getCharacteristicWithUUID(_ uuid: CGMServiceCharacteristicUUID) -> CBCharacteristic? {
        return getCharacteristicForServiceUUID(.cgmService, withUUIDString: uuid.rawValue)
    }
}
