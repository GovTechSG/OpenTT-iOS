//
//  PassportModalViewController.swift
//  OpenTraceTogether

import Foundation
import UIKit

class PassportModalViewController: UIViewController {

    @IBInspectable var screenName: String!

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AnalyticManager.setScreenName(screenName: screenName, screenClass: "PassportModalViewController")
    }

    @IBAction func dismiss() {
        dismiss(animated: true, completion: nil )
    }

}
