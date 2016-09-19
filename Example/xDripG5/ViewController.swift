//
//  ViewController.swift
//  xDrip5
//
//  Created by Nathan Racklyeft on 10/1/15.
//  Copyright © 2015 Nathan Racklyeft. All rights reserved.
//

import UIKit
import HealthKit
import xDripG5

class ViewController: UIViewController, TransmitterDelegate, UITextFieldDelegate {

    @IBOutlet weak var titleLabel: UILabel!

    @IBOutlet weak var subtitleLabel: UILabel!

    @IBOutlet weak var passiveModeEnabledSwitch: UISwitch!

    @IBOutlet weak var stayConnectedSwitch: UISwitch!

    @IBOutlet weak var transmitterIDField: UITextField!

    @IBOutlet weak var scanningIndicatorView: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()

        passiveModeEnabledSwitch.isOn = AppDelegate.sharedDelegate.transmitter?.passiveModeEnabled ?? false

        stayConnectedSwitch.isOn = AppDelegate.sharedDelegate.transmitter?.stayConnected ?? false

        transmitterIDField.text = AppDelegate.sharedDelegate.transmitter?.ID
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        updateIndicatorViewDisplay()
    }

    // MARK: - Actions

    func updateIndicatorViewDisplay() {
        if let transmitter = AppDelegate.sharedDelegate.transmitter, transmitter.isScanning {
            scanningIndicatorView.startAnimating()
        } else {
            scanningIndicatorView.stopAnimating()
        }
    }

    @IBAction func toggleStayConnected(_ sender: UISwitch) {
        AppDelegate.sharedDelegate.transmitter?.stayConnected = sender.isOn
        UserDefaults.standard.stayConnected = sender.isOn

        updateIndicatorViewDisplay()
    }

    @IBAction func togglePassiveMode(_ sender: UISwitch) {
        AppDelegate.sharedDelegate.transmitter?.passiveModeEnabled = sender.isOn
        UserDefaults.standard.passiveModeEnabled = sender.isOn
    }

    // MARK: - UITextFieldDelegate

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let text = textField.text {
            let newString = text.replacingCharacters(in: range.rangeOfString(text), with: string)

            if newString.characters.count > 6 {
                return false
            } else if newString.characters.count == 6 {
                AppDelegate.sharedDelegate.transmitter?.ID = newString
                UserDefaults.standard.transmitterID = newString

                textField.text = newString

                textField.resignFirstResponder()

                return false
            }
        }

        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.text?.characters.count != 6 {
            textField.text = UserDefaults.standard.transmitterID
        }
    }

    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }

    // MARK: - TransmitterDelegate

    func transmitter(_ transmitter: Transmitter, didError error: Error) {
        titleLabel.text = NSLocalizedString("Error", comment: "Title displayed during error response")

        subtitleLabel.text = "\(error)"
    }

    func transmitter(_ transmitter: Transmitter, didRead glucose: Glucose) {
        let unit = HKUnit.milligramsPerDeciliter()
        if let value = glucose.glucose?.doubleValue(for: unit) {
            titleLabel.text = "\(value) \(unit.unitString)"
        } else {
            titleLabel.text = String(describing: glucose.state)
        }


        let date = glucose.readDate
        subtitleLabel.text = DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .long)
    }

    func transmitter(_ transmitter: Transmitter, didReadUnknownData data: Data) {
        titleLabel.text = NSLocalizedString("Unknown Data", comment: "Title displayed during unknown data response")
        subtitleLabel.text = data.hexadecimalString
    }
}


private extension NSRange {
    func rangeOfString(_ string: String) -> Range<String.Index> {
        let startIndex = string.characters.index(string.startIndex, offsetBy: location)
        let endIndex = string.characters.index(startIndex, offsetBy: length)
        return startIndex..<endIndex
    }
}

