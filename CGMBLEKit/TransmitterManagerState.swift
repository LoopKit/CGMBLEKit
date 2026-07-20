//
//  TransmitterManagerState.swift
//  CGMBLEKit
//
//  Created by Pete Schwamb on 9/11/23.
//  Copyright © 2023 LoopKit Authors. All rights reserved.
//

import Foundation
import LoopKit

public struct TransmitterManagerState: RawRepresentable, Equatable {
    public typealias RawValue = CGMManager.RawStateValue

    public static let version = 1

    public static let defaultSensorLifeDays = 10

    /// Selectable session lengths for Anubis-modded transmitters.
    public static let sensorLifeDaysRange = 10...60

    static func clampedSensorLifeDays(_ days: Int) -> Int {
        return min(max(days, sensorLifeDaysRange.lowerBound), sensorLifeDaysRange.upperBound)
    }

    public var transmitterID: String

    public var passiveModeEnabled: Bool = true

    public var transmitterStartDate: Date?

    public var sensorStartOffset: UInt32?

    public var shouldSyncToRemoteService: Bool

    /// Transmitter-reported lifetime in days (90 for stock G6, 180 for
    /// Anubis-modded). `nil` until the first version-rx frame comes in.
    public var transmitterExpiryInDays: UInt16?

    /// User-configured session length; only honored for Anubis (see `sensorLife`).
    public var sensorLifeDays: Int

    public init(
        transmitterID: String,
        shouldSyncToRemoteService: Bool = true,
        transmitterStartDate: Date? = nil,
        sensorStartOffset: UInt32? = nil,
        transmitterExpiryInDays: UInt16? = nil,
        sensorLifeDays: Int = Self.defaultSensorLifeDays
    ) {
        self.transmitterID = transmitterID
        self.shouldSyncToRemoteService = shouldSyncToRemoteService
        self.transmitterStartDate = transmitterStartDate
        self.sensorStartOffset = sensorStartOffset
        self.transmitterExpiryInDays = transmitterExpiryInDays
        self.sensorLifeDays = Self.clampedSensorLifeDays(sensorLifeDays)
    }

    public init?(rawValue: RawValue) {
        guard let transmitterID = rawValue["transmitterID"] as? String
        else {
            return nil
        }

        let shouldSyncToRemoteService = rawValue["shouldSyncToRemoteService"] as? Bool ?? false

        let transmitterStartDate = rawValue["transmitterStartDate"] as? Date

        let sensorStartOffset = rawValue["sensorStartOffset"] as? UInt32

        let transmitterExpiryInDays = (rawValue["transmitterExpiryInDays"] as? UInt16)
            ?? (rawValue["transmitterExpiryInDays"] as? Int).map { UInt16($0) }

        let sensorLifeDays = rawValue["sensorLifeDays"] as? Int ?? Self.defaultSensorLifeDays

        self.init(
            transmitterID: transmitterID,
            shouldSyncToRemoteService: shouldSyncToRemoteService,
            transmitterStartDate: transmitterStartDate,
            sensorStartOffset: sensorStartOffset,
            transmitterExpiryInDays: transmitterExpiryInDays,
            sensorLifeDays: sensorLifeDays
        )
    }

    public var rawValue: RawValue {
        var rval: RawValue = [
            "transmitterID": transmitterID,
            "shouldSyncToRemoteService": shouldSyncToRemoteService
        ]

        rval["transmitterStartDate"] = transmitterStartDate
        rval["sensorStartOffset"] = sensorStartOffset
        rval["transmitterExpiryInDays"] = transmitterExpiryInDays.map { Int($0) }
        rval["sensorLifeDays"] = sensorLifeDays

        return rval
    }

    /// `true` once the transmitter has reported the Anubis 180-day lifetime.
    public var isAnubis: Bool {
        return transmitterExpiryInDays == 180
    }

    /// Active session length: `sensorLifeDays` for Anubis, else the stock 10 days.
    public var sensorLife: TimeInterval {
        return .hours(24 * Double(isAnubis ? sensorLifeDays : Self.defaultSensorLifeDays))
    }
}
