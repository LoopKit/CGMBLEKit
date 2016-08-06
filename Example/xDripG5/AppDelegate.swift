//
//  AppDelegate.swift
//  xDrip5
//
//  Created by Nathan Racklyeft on 10/1/15.
//  Copyright © 2015 Nathan Racklyeft. All rights reserved.
//

import UIKit
import xDripG5
import CoreBluetooth

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, TransmitterDelegate {

    var window: UIWindow?

    static var sharedDelegate: AppDelegate {
        return UIApplication.sharedApplication().delegate as! AppDelegate
    }

    var transmitter: Transmitter?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        transmitter = Transmitter(
            ID: NSUserDefaults.standardUserDefaults().transmitterID,
            passiveModeEnabled: NSUserDefaults.standardUserDefaults().passiveModeEnabled
        )
        transmitter?.stayConnected = NSUserDefaults.standardUserDefaults().stayConnected
        transmitter?.delegate = self

        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.

        if let transmitter = transmitter where !transmitter.stayConnected {
            transmitter.stopScanning()
        }
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.

        transmitter?.resumeScanning()
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    // MARK: - TransmitterDelegate

    private let dateFormatter: NSDateFormatter = {
        let dateFormatter = NSDateFormatter()

        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")

        return dateFormatter
    }()

    func transmitter(transmitter: Transmitter, didError error: ErrorType) {
        if let vc = window?.rootViewController as? TransmitterDelegate {
            dispatch_async(dispatch_get_main_queue()) {
                vc.transmitter(transmitter, didError: error)
            }
        }
    }

    func transmitter(transmitter: Transmitter, didRead glucose: Glucose) {
        if let vc = window?.rootViewController as? TransmitterDelegate {
            dispatch_async(dispatch_get_main_queue()) {
                vc.transmitter(transmitter, didRead: glucose)
            }
        }
    }
}
