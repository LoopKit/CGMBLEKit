//
//  ViewController.swift
//  xDrip5
//
//  Created by Nathan Racklyeft on 10/1/15.
//  Copyright © 2015 Nathan Racklyeft. All rights reserved.
//

import UIKit

class ViewController: UIViewController, TransmitterDelegate, UITextFieldDelegate {

    @IBOutlet weak var titleLabel: UILabel!

    @IBOutlet weak var subtitleLabel: UILabel!

    @IBOutlet weak var passiveModeEnabledSwitch: UISwitch!

    @IBOutlet weak var stayConnectedSwitch: UISwitch!

    @IBOutlet weak var transmitterIDField: UITextField!

    @IBOutlet weak var scanningIndicatorView: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()

        passiveModeEnabledSwitch.on = AppDelegate.sharedDelegate.transmitter?.passiveModeEnabled ?? false

        stayConnectedSwitch.on = AppDelegate.sharedDelegate.transmitter?.stayConnected ?? false

        transmitterIDField.text = AppDelegate.sharedDelegate.transmitter?.ID
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        updateIndicatorViewDisplay()
    }

    // MARK: - Actions

    func updateIndicatorViewDisplay() {
        if let transmitter = AppDelegate.sharedDelegate.transmitter where transmitter.isScanning {
            scanningIndicatorView.startAnimating()
        } else {
            scanningIndicatorView.stopAnimating()
        }
    }

    @IBAction func toggleStayConnected(sender: UISwitch) {
        AppDelegate.sharedDelegate.transmitter?.stayConnected = sender.on
        NSUserDefaults.standardUserDefaults().stayConnected = sender.on

        updateIndicatorViewDisplay()
    }

    @IBAction func togglePassiveMode(sender: UISwitch) {
        AppDelegate.sharedDelegate.transmitter?.passiveModeEnabled = sender.on
        NSUserDefaults.standardUserDefaults().passiveModeEnabled = sender.on
    }

    // MARK: - UITextFieldDelegate

    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if let text = textField.text {
            let newString = text.stringByReplacingCharactersInRange(range.rangeOfString(text), withString: string)

            if newString.characters.count > 6 {
                return false
            } else if newString.characters.count == 6 {
                AppDelegate.sharedDelegate.transmitter?.ID = newString
                NSUserDefaults.standardUserDefaults().transmitterID = newString

                textField.text = newString

                textField.resignFirstResponder()

                return false
            }
        }

        return true
    }

    func textFieldDidEndEditing(textField: UITextField) {
        if textField.text?.characters.count != 6 {
            textField.text = NSUserDefaults.standardUserDefaults().transmitterID
        }
    }

    func textFieldShouldEndEditing(textField: UITextField) -> Bool {
        return true
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        return true
    }

    // MARK: - TransmitterDelegate

    func transmitter(transmitter: Transmitter, didError error: ErrorType) {
        titleLabel.text = NSLocalizedString("Error", comment: "Title displayed during error response")

        subtitleLabel.text = "\(error)"
    }

    func transmitter(transmitter: Transmitter, didReadGlucose glucose: GlucoseRxMessage) {
        titleLabel.text = NSNumberFormatter.localizedStringFromNumber(NSNumber(short: Int16(glucose.glucose)), numberStyle: .NoStyle)

        if let startTime = transmitter.startTimeInterval {
            let date = NSDate(timeIntervalSince1970: startTime).dateByAddingTimeInterval(NSTimeInterval(glucose.timestamp))

            subtitleLabel.text = NSDateFormatter.localizedStringFromDate(date, dateStyle: .NoStyle, timeStyle: .LongStyle)
        } else {
            subtitleLabel.text = "Unknown time"
        }

    }

}


private extension NSRange {
    func rangeOfString(string: String) -> Range<String.Index> {
        let startIndex = string.startIndex.advancedBy(location)
        let endIndex = startIndex.advancedBy(length)
        return startIndex..<endIndex
    }
}

