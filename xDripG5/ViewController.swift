//
//  ViewController.swift
//  xDrip5
//
//  Created by Nathan Racklyeft on 10/1/15.
//  Copyright © 2015 Nathan Racklyeft. All rights reserved.
//

import UIKit

class ViewController: UIViewController, TransmitterDelegate {

    @IBOutlet weak var titleLabel: UILabel!

    @IBOutlet weak var subtitleLabel: UILabel!

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

