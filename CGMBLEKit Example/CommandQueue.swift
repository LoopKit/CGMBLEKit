//
//  CommandQueue.swift
//  CGMBLEKit Example
//
//  Created by Paul Dickens on 25/03/2018.
//  Copyright © 2018 LoopKit Authors. All rights reserved.
//

import Foundation
import xDripG5


class CommandQueue {
    private var list = Array<Command>()
    private var lock = os_unfair_lock()

    var isEmpty: Bool {
        return list.isEmpty
    }

    func enqueue(_ element: Command) {
        os_unfair_lock_lock(&lock)
        list.append(element)
        os_unfair_lock_unlock(&lock)
    }

    func dequeue() -> Command? {
        if !list.isEmpty {
            os_unfair_lock_lock(&lock)
            defer {
                os_unfair_lock_unlock(&lock)
            }
            return list.removeFirst()
        } else {
            return nil
        }
    }
}
