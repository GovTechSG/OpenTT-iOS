//
//  IntroViewController.swift

//  OpenTraceTogether

import UIKit
import FirebaseAnalytics
import FirebaseAuth

class IntroViewController: UIViewController {
    @IBOutlet weak var testLocalizationLabel: UILabel!
    @IBOutlet weak var openLetterBtn: UIButton!
    @IBOutlet weak var languageListBtn: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        languageListBtn.titleLabel?.textAlignment = .center
        openLetterBtn.accessibilityLabel = NSLocalizedString("TapLetter", comment: "Tap letter to open")
        let tapToChangeLang = NSLocalizedString("TapToChangeLanguage", comment: "Tap to change language to any one of the following")
        languageListBtn.accessibilityLabel = "\(tapToChangeLang). Chinese, Melayu, Tamil, Hindi, Bangla, Thai, Burmese"
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AnalyticManager.setScreenName(screenName: "OnboardwithLove", screenClass: "IntroViewController")
    }

    @IBAction func goToSettings(_ sender: Any) {
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
    }
}
