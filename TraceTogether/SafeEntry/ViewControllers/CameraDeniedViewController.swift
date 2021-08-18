//
//  CameraDeniedViewController.swift
//  OpenTraceTogether

import UIKit
import AVFoundation

class CameraDeniedViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // no need to put observer as permissions change requires app reboot
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AnalyticManager.setScreenName(screenName: "SENoCameraPermission", screenClass: "CameraDeniedViewController")
    }

    @IBAction func backButtonPressed(_ sender: UIButton) {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    @IBAction func goToSettingsButtonPressed(_ sender: UIButton) {
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)

    }
}
