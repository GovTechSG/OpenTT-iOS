//
//  AppNotWorkingModalVC.swift
//  OpenTraceTogether

import Foundation
import UIKit

class AppNotWorkingModalVC: UIViewController, Nondismissable {
    @IBOutlet weak var bluetoothStack: UIStackView!
    @IBOutlet weak var notificationsStack: UIStackView!

    @IBOutlet weak var bluetoothImg: UIImageView!
    @IBOutlet weak var notificationsImg: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        displayMissingAuthorizations()
    }

    func displayMissingAuthorizations() {
        let isBluetoothAuthorized = PermissionsUtils.isBluetoothAuthorized()
        let isPushNotificationsAuthorized = PermissionsUtils.isPushNotificationsAuthorised()
        if !isBluetoothAuthorized {
            bluetoothImg?.image = UIImage(named: "bullet1")
            notificationsImg?.image = UIImage(named: "bullet2")
        } else {
            if !isPushNotificationsAuthorized {
                notificationsImg?.image = UIImage(named: "bullet1")
            }
        }
        bluetoothStack?.isHidden = isBluetoothAuthorized
        notificationsStack?.isHidden = isPushNotificationsAuthorized
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AnalyticManager.setScreenName(screenName: "HomeAppNotWorking", screenClass: "AppNotWorkingModalVC", details:
                                        ["isAllPermissionsAuthorized": "\(PermissionsUtils.isAllPermissionsAuthorized())",
                                         "isBluetoothAuthorized": "\(PermissionsUtils.isBluetoothAuthorized())",
                                         "isPushNotificationsAuthorised": "\(PermissionsUtils.isPushNotificationsAuthorised())",
                                         "isBluetoothOn": "\(PermissionsUtils.isBluetoothOn())"])
    }

    @IBAction func goToSettings(_ sender: Any) {
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
    }
}
