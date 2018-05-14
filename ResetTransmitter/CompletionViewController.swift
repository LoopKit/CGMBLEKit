//
//  CompletionViewController.swift
//  ResetTransmitter
//
//  Copyright © 2018 LoopKit Authors. All rights reserved.
//

import UIKit
import UserNotifications

class CompletionViewController: UITableViewController {
    struct Data {
        let title: String
        let message: String
    }

    @IBOutlet weak var textView: UITextView!

    @IBOutlet weak var navBar: UINavigationItem!

    var data: Data?

    override func viewDidLoad() {
        super.viewDidLoad()

        navBar.title = data?.title
        textView.text = data?.message

        if UIApplication.shared.applicationState == .background {
            let content = UNMutableNotificationContent()
            content.badge = 1
            content.title = navBar.title!
            content.body = textView.text
            content.sound = .default()

            let request = UNNotificationRequest(identifier: "Completion", content: content, trigger: nil)

            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        }
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return nil
    }
}
