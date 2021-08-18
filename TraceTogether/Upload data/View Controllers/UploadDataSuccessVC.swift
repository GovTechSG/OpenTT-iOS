//
//  UploadDataSuccessVC.swift
//  OpenTraceTogether

import Foundation
import UIKit

class UploadDataSuccessVC: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.hidesBackButton = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AnalyticManager.setScreenName(screenName: "UploadCompleted", screenClass: "UploadDataSuccessVC")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.navigationController?.popToRootViewController(animated: false)
    }

    @IBAction func doneBtnTapped(_ sender: UIButton) {
        // Bring user back to home tab
        self.navigationController?.tabBarController?.selectedIndex = 0
    }
}
