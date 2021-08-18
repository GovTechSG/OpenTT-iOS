//
// TraceTogetherPausedViewController.swift (work in progress)
//  OpenTraceTogether

import UIKit
import FirebaseAnalytics

class TraceTogetherPausedViewController: UIViewController {

    var pauseTime = Int()

    override func viewDidLoad() {
        super.viewDidLoad()
        print(pauseTime)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AnalyticManager.setScreenName(screenName: "HomeTTPaused", screenClass: "TraceTogetherPausedViewController")
    }

    @IBAction func resumeNowButtonPressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
}
