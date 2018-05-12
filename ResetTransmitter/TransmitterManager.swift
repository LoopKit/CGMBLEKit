//
//  TransmitterManager.swift
//  ResetTransmitter
//
//  Copyright © 2018 LoopKit Authors. All rights reserved.
//

import CGMBLEKit
import os.log


class ResetManager: TransmitterManager {
    override func dequeuePendingCommand(for transmitter: Transmitter, sessionStartDate: Date?) -> Command? {
        if case .actioning = state {
            return .resetTransmitter
        }

        return nil
    }

    override func transmitter(_ transmitter: Transmitter, didComplete command: Command) {
        if case .resetTransmitter = command {
            state = .completed(title: "Reset Complete", message: "The transmitter has been successfully reset. Connect it to the app to begin a new sensor session.")
        }
    }
}


class RestartManager: TransmitterManager {
    enum Action {
        case stopping
        case starting
    }

    private var action: Action {
        get {
            return lockedAction.value
        }
        set {
            let oldValue = action
            lockedAction.value = newValue
            os_log("State changed: %{public}@ -> %{public}@", log: log, type: .debug, String(describing: oldValue), String(describing: newValue))
         }
    }
    private let lockedAction = Locked(Action.stopping)

    private let log = OSLog(subsystem: "com.loopkit.CGMBLEKit", category: "RestartManager")

    override func dequeuePendingCommand(for transmitter: Transmitter, sessionStartDate: Date?) -> Command? {
        if case .actioning(_, let date) = state {
            let twoHoursAgo = date.addingTimeInterval(-2*60*60)
            switch action {
            case .stopping:
                guard let startDate = sessionStartDate else {
                    state = .completed(title: "Restart Failed", message: "The sensor restart was unsuccessful. The sensor was not in an active session when restart was attempted.")
                    return nil
                }
                guard startDate < twoHoursAgo else {
                    state = .completed(title: "Restart Failed", message: "The sensor restart was unsuccessful. The sensor session was less than two hours old when restart was attempted.")
                    return nil
                }
                return .stopSensor(at: twoHoursAgo)
            case .starting:
                return .startSensor(at: twoHoursAgo)
            }
        }

        return nil
    }

    override func transmitter(_ transmitter: Transmitter, didComplete command: Command) {
        if case .stopSensor = command {
            action = .starting
        }
        if case .startSensor = command {
            state = .completed(title: "Restart Complete", message: "The sensor has been successfully restarted. Connect it to the app for initial calibrations.")
        }
    }
}


class TransmitterManager: TransmitterCommandSource {
    enum State {
        case initialized
        case actioning(transmitter: Transmitter, at: Date)
        case completed(title: String, message: String)
    }

    fileprivate(set) var state: State {
        get {
            return lockedState.value
        }
        set {
            let oldValue = state
            
            if case .actioning(let transmitter, _) = oldValue {
                transmitter.stopScanning()
                transmitter.delegate = nil
                transmitter.commandSource = nil
            }
            
            lockedState.value = newValue
            
            if case .actioning(let transmitter, _) = newValue {
                transmitter.delegate = self
                transmitter.commandSource = self
                transmitter.resumeScanning()
            }
            
            os_log("State changed: %{public}@ -> %{public}@", log: log, type: .debug, String(describing: oldValue), String(describing: newValue))
            delegate?.transmitterManager(self, didChangeStateFrom: oldValue)
        }
    }
    private let lockedState = Locked(State.initialized)

    private let log = OSLog(subsystem: "com.loopkit.CGMBLEKit", category: "TransmitterManager")

    weak var delegate: TransmitterManagerDelegate?

    func dequeuePendingCommand(for transmitter: Transmitter, sessionStartDate: Date?) -> Command? {
        state = .completed(title: "Default title", message: "Default message")
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
        case .actioning(let transmitter, _):
            guard transmitter.ID != id else {
                return
            }
        }
        
        state = .actioning(transmitter: Transmitter(id: id, passiveModeEnabled: false), at: Date())
        
        #if targetEnvironment(simulator)
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) {
            self.delegate?.transmitterManager(self, didError: TransmitterError.controlError("Simulated Error"))
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) {
                if case .actioning(let transmitter, _) = self.state {
                    while let command = self.dequeuePendingCommand(for: transmitter, sessionStartDate: nil) {
                        self.transmitter(transmitter, didComplete: command)
                    }
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
