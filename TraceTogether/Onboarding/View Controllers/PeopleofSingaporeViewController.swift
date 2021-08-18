//
//  HowItWorksViewController.swift

//  OpenTraceTogether

import UIKit
import FirebaseAuth

class PeopleofSingaporeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        OnboardingManager.shared.hasViewedLoveLetter = true
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AnalyticManager.setScreenName(screenName: "OnboardDearSg", screenClass: "PeopleofSingaporeViewController")
    }
    @IBAction func backBtnClicked(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}
