//
//  TransmitterViewController.swift
//  ResetTransmitter
//
//  Copyright © 2018 LoopKit Authors. All rights reserved.
//

import UIKit
import UserNotifications


class TransmitterViewController: UITableViewController {

    private enum State {
        case empty
        case needsConfiguration
        case configured
        case actioning
        case completed
    }

    private var state: State = .empty {
        didSet {
            guard oldValue != state else {
                return
            }

            lastError = nil
            updateButtonState()
            updateTransmitterIDFieldState()
            updateStatusIndicatorState()

            if state == .completed {
                performSegue(withIdentifier: "CompletionViewController", sender: self)
            }
        }
    }

    @IBOutlet var hairlines: [UIView]!

    @IBOutlet weak var actionButton: Button!

    @IBOutlet weak var transmitterIDField: TextField!

    @IBOutlet weak var spinner: UIActivityIndicatorView!

    @IBOutlet weak var errorLabel: UILabel!

    @IBOutlet weak var buttonTopSpace: NSLayoutConstraint!

    private var needsButtonTopSpaceUpdate = true

    private var lastError: Error?

    private lazy var transmitterManager: TransmitterManager = {
        let manager = RestartManager()
        manager.delegate = self
        return manager
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        for hairline in hairlines {
            for constraint in hairline.constraints {
                constraint.constant = 1 / UIScreen.main.scale
            }
        }

        self.navigationController?.delegate = self
        self.navigationController?.navigationBar.shadowImage = UIImage()

        state = .needsConfiguration
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .sound, .alert]) { (success, error) in
            //
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        state = .needsConfiguration
    }

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

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return nil
    }

    // MARK: - Actions

    @IBAction func performAction(_ sender: Any) {
        switch state {
        case .empty, .needsConfiguration:
            // Actions are not allowed
            break
        case .configured:
            // Begin reset
            manageTransmitter(withID: transmitterIDField.text ?? "")
        case .actioning:
            // Cancel pending reset
            transmitterManager.cancel()
        case .completed:
            // Ignore actions here
            break
        }
    }

    private func manageTransmitter(withID id: String) {
        let controller = UIAlertController(
            title: NSLocalizedString("Are you sure you want to reset this transmitter?", comment: "Title of the reset confirmation sheet"),
            message: NSLocalizedString("It will take up to 10 minutes to complete.", comment: "Message of the reset confirmation sheet"), preferredStyle: .actionSheet
        )

        controller.addAction(UIAlertAction(
            title: NSLocalizedString("Reset", comment: "Reset button title"),
            style: .destructive,
            handler: { (action) in
                self.transmitterManager.manage(withID: id)
            }
        ))

        controller.addAction(UIAlertAction(
            title: NSLocalizedString("Cancel", comment: "Title of button to cancel reset"),
            style: .cancel,
            handler: nil
        ))

        present(controller, animated: true, completion: nil)
    }
}


// MARK: - UI state management
extension TransmitterViewController {
    private func updateButtonState() {
        switch state {
        case .empty, .needsConfiguration:
            actionButton.isEnabled = false
        case .configured, .actioning, .completed:
            actionButton.isEnabled = true
        }

        switch state {
        case .empty, .needsConfiguration, .configured:
            actionButton.setTitle(NSLocalizedString("Reset", comment: "Title of button to begin reset"), for: .normal)
            actionButton.tintColor = .red
        case .actioning, .completed:
            actionButton.setTitle(NSLocalizedString("Cancel", comment: "Title of button to cancel reset"), for: .normal)
            actionButton.tintColor = .darkGray
        }
    }

    private func updateTransmitterIDFieldState() {
        switch state {
        case .empty, .needsConfiguration:
            transmitterIDField.text = ""
            transmitterIDField.isEnabled = true
        case .configured:
            transmitterIDField.isEnabled = true
        case .actioning, .completed:
            transmitterIDField.isEnabled = false
        }
    }

    private func updateStatusIndicatorState() {
        switch self.state {
        case .empty, .needsConfiguration, .configured, .completed:
            self.spinner.stopAnimating()
            self.errorLabel.superview?.isHidden = true
        case .actioning:
            self.spinner.startAnimating()
            if let error = lastError {
                self.errorLabel.text = String(describing: error)
            }
            self.errorLabel.superview?.isHidden =
                    (self.lastError == nil)
        }
    }
}


extension TransmitterViewController: TransmitterManagerDelegate {
    func transmitterManager(_ manager: TransmitterManager, didError error: Error) {
        DispatchQueue.main.async {
            self.lastError = error
            self.updateStatusIndicatorState()
        }
    }

    func transmitterManager(_ manager: TransmitterManager, didChangeStateFrom oldState: TransmitterManagerState) {
        DispatchQueue.main.async {
            switch manager.state {
            case .initialized:
                self.state = .configured
            case .actioning:
                self.state = .actioning
            case .completed:
                self.state = .completed
            }
        }
    }
}

extension TransmitterViewController: UINavigationControllerDelegate {
    func navigationControllerSupportedInterfaceOrientations(_ navigationController: UINavigationController) -> UIInterfaceOrientationMask {
        return .portrait
    }
}

extension TransmitterViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text, let stringRange = Range(range, in: text) else {
            state = .needsConfiguration
            return true
        }

        let newText = text.replacingCharacters(in: stringRange, with: string)

        if newText.count >= 6 {
            if newText.count == 6 {
                textField.text = newText
                textField.resignFirstResponder()
            }

            state = .configured
            return false
        }

        state = .needsConfiguration
        return true
    }
}
