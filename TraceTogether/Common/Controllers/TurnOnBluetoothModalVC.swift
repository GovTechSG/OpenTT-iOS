//
//  TurnOnBluetoothModalVC.swift
//  OpenTraceTogether

import Foundation
import UIKit

class TurnOnBluetoothModalVC: UIViewController, Nondismissable {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
         AnalyticManager.setScreenName(screenName: "HomeBluetoothOff", screenClass: "TurnOnBluetoothModalVC")
    }
}
