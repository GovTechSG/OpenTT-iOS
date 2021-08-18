//
//  ErrorLogsSubmittedSuccessfullyViewController.swift
//  OpenTraceTogether

import UIKit

class ErrorLogsSubmittedSuccessfullyViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = NSLocalizedString("SubmitErrorLogs", comment: "")
    }

    @IBAction func backToHome() {
        tabBarController?.selectedIndex = 0
        navigationController?.popToRootViewController(animated: false)
    }
}
