//
//  SessionStartTxMessage.swift
//  xDripG5
//
//  Created by Nathan Racklyeft on 3/26/16.
//  Copyright © 2016 Nathan Racklyeft. All rights reserved.
//

import Foundation


struct SessionStartTxMessage: RespondableMessage {
    typealias Response = SessionStartRxMessage

    /// Time since activation in Dex seconds
    let time: UInt32

    /// Time in seconds since Unix Epoch
    let timeEpoch: UInt32

    var data: Data {
        var data = Data(for: .sessionStartTx)
        data.append(time)
        data.append(timeEpoch)
        return data.appendingCRC()
    }
}
