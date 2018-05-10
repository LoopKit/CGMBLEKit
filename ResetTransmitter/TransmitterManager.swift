//
//  TransmitterManager.swift
//  ResetTransmitter
//
//  Copyright © 2018 LoopKit Authors. All rights reserved.
//

import CGMBLEKit
import os.log


class TransmitterManager {
    enum State {
        case initialized
        case actioning(transmitter: Transmitter)
        case completed(succeeded: Bool, message: String)
    }

    private(set) var state: State {
        get {
            return lockedState.value
        }
        set {
            let oldValue = state
            
            if case .actioning(let transmitter) = oldValue {
                transmitter.stopScanning()
                transmitter.delegate = nil
                transmitter.commandSource = nil
            }
            
            lockedState.value = newValue
            
            if case .actioning(let transmitter) = newValue {
                transmitter.delegate = self
                transmitter.commandSource = self
                transmitter.resumeScanning()
            }
            
            os_log("State changed: %{public}@ -> %{public}@", log: log, type: .debug, String(describing: oldValue), String(describing: newValue))
            delegate?.transmitterManager(self, didChangeStateFrom: oldValue)
        }
    }
    private let lockedState = Locked(State.initialized)
    
    private let log = OSLog(subsystem: "com.loopkit.CGMBLEKit", category: "RestartManager")
    
    weak var delegate: TransmitterManagerDelegate?
}


protocol TransmitterManagerDelegate: class {
    func transmitterManager(_ manager: TransmitterManager, didError error: Error)

    func transmitterManager(_ manager: TransmitterManager, didChangeStateFrom oldState: TransmitterManager.State)
}


extension TransmitterManager {
    
    func cancel() {
        guard case .actioning = state else {
            return
        }
        
        state = .initialized
    }
    
    func manage(withID id: String) {
        guard id.count == 6 else {
            return
        }
        
        switch state {
        case .initialized, .completed:
            break
        case .actioning(let transmitter):
            guard transmitter.ID != id else {
                return
            }
        }
        
        state = .actioning(transmitter: Transmitter(id: id, passiveModeEnabled: false))
        
        #if targetEnvironment(simulator)
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) {
            self.delegate?.transmitterManager(self, didError: TransmitterError.controlError("Simulated Error"))
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) {
                if case .actioning = self.state {
                    self.state = .completed(succeeded: true, message: "The transmitter has been successfully restarted. Connect it to the app for initial calibrations.")
                }
            }
        }
        #endif
    }
}


extension TransmitterManager: TransmitterDelegate {
    func transmitter(_ transmitter: Transmitter, didError error: Error) {
        os_log("Transmitter error: %{public}@", log: log, type: .error, String(describing: error))
        delegate?.transmitterManager(self, didError: error)
    }
    
    func transmitter(_ transmitter: Transmitter, didRead glucose: Glucose) {
        // Not interested
    }
    
    func transmitter(_ transmitter: Transmitter, didReadBackfill glucose: [Glucose]) {
        // Not interested
    }
    
    func transmitter(_ transmitter: Transmitter, didReadUnknownData data: Data) {
        // Not interested
    }
}


extension TransmitterManager: TransmitterCommandSource {
    func dequeuePendingCommand(for transmitter: Transmitter, sessionStartDate: Date?) -> Command? {
        state = .completed(succeeded: true, message: "The transmitter has been successfully reset. Connect it to the app to begin a new sensor session.")
        return nil
    }
    
    func transmitter(_ transmitter: Transmitter, didFail command: Command, with error: Error) {
        os_log("Command error: %{public}@", log: log, type: .error, String(describing: error))
        delegate?.transmitterManager(self, didError: error)
    }
    
    func transmitter(_ transmitter: Transmitter, didComplete command: Command) {
        // subclass and implement
    }
}
