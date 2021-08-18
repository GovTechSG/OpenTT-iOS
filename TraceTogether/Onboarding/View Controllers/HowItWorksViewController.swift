//
//  HowItWorksViewController.swift
//  OpenTraceTogether

import UIKit
import Foundation

class HowItWorksViewController: UIViewController {

    @IBOutlet weak var dataUseInfoLabel: UILabel!
    @IBOutlet weak var headerImageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        let dataUseInfoLocalizedText = NSLocalizedString("DataUseInfo", comment: "")
        dataUseInfoLabel.attributedText = Markup.getAttributedString(markupString: dataUseInfoLocalizedText, font: UIFont.systemFont(ofSize: 16))
        let dataUseInfoWithoutTags = dataUseInfoLocalizedText.removeHTMLTag()
        dataUseInfoLabel.accessibilityLabel = dataUseInfoWithoutTags.replacingOccurrences(of: "MOH", with: "M O H")

        view.layoutIfNeeded()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AnalyticManager.setScreenName(screenName: "OnboardDataStoredSecurely", screenClass: "HowItWorksViewController")
    }

    @IBAction func backBtnClicked(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "HowItWorksToMobileNumberSegue" {
            OnboardingManager.shared.completedIWantToHelp = true
        }
    }

}
