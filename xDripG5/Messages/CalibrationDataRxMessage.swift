//
//  CalibrationDataRxMessage.swift
//  Pods
//
//  Created by Nate Racklyeft on 9/18/16.
//
//

import Foundation


struct CalibrationDataRxMessage: TransmitterRxMessage {
    init?(data: Data) {
        guard data.count == 19 && data.isCRCValid else {
            return nil
        }

        guard data.starts(with: .calibrationDataRx) else {
            return nil
        }
    }
}
