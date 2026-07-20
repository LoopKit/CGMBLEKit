//
//  TransmitterVersionTxMessage.swift
//  xDripG5
//
//  Created by Nathan Racklyeft on 3/26/16.
//  Copyright © 2016 Nathan Racklyeft. All rights reserved.
//

import Foundation


struct TransmitterVersionTxMessage: RespondableMessage {
    typealias Response = TransmitterVersionRxMessage

    var data: Data {
        return Data(for: .transmitterVersionTx).appendingCRC()
    }
}
