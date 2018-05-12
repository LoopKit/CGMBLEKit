//
//  SelectorViewController.swift
//  ResetTransmitter
//
//  Created by Paul Dickens on 12/5/18.
//  Copyright © 2018 LoopKit Authors. All rights reserved.
//

import UIKit

class SelectorViewController: UITableViewController {

    @IBOutlet weak var modePicker: UIPickerView!

    @IBOutlet weak var buttonTopSpace: NSLayoutConstraint!

    private var needsButtonTopSpaceUpdate = true

    override func viewDidLoad() {
        super.viewDidLoad()

        self.modePicker.delegate = self
        self.modePicker.dataSource = self
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Update the constraint once to fit the height of the screen
        if indexPath.section == tableView.numberOfSections - 1 && needsButtonTopSpaceUpdate {
            needsButtonTopSpaceUpdate = false
            let currentValue = buttonTopSpace.constant
            let suggestedValue = max(0, tableView.bounds.size.height - tableView.contentSize.height - tableView.safeAreaInsets.bottom - tableView.safeAreaInsets.top)

            if abs(currentValue - suggestedValue) > .ulpOfOne {
                buttonTopSpace.constant = suggestedValue
            }
        }

        return UITableViewAutomaticDimension
    }


    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */


    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationViewController = segue.destination as? TransmitterViewController {
            destinationViewController.mode = selectedMode
        }
    }
}

extension SelectorViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return Mode.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return Mode(rawValue: row)!.description
    }

    var selectedMode: Mode {
        return Mode(rawValue: modePicker.selectedRow(inComponent: 0))!
    }
}
