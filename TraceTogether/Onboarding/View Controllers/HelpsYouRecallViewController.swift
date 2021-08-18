//
//  HelpsYouRecallViewController.swift

//
//  OpenTraceTogether

import UIKit
import Foundation

class HelpsYouRecallViewController: UIViewController {

    @IBOutlet weak var logoLabel: UILabel!
    @IBOutlet weak var labelOne: UILabel!
    @IBOutlet weak var labelTwo: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        if let oldAttrString = logoLabel.attributedText {
            let newAttributedString = LocalizationHelper.updateLocalizedAttributedString(localizedKey: "TraceTogetherLogoLabel", localizedComment: "TraceTogether", oldAttrString)
            if let languageCode = Locale.current.languageCode {
                switch languageCode {
                case "en", "ta", "bn", "my", "th":
                    print("Use Storyboard Attributed Text")
                case "zh", "ms", "hi":
                    logoLabel.attributedText = newAttributedString
                default:
                    print("nothing here")
                }
            }

        }
        let labelOneLocalizedText = NSLocalizedString("HelpsYouRecallLabel1", comment: "Helps you remember where you went and who you were with in the past few weeks.")
        let labelOneLocalizedBoldText = NSLocalizedString("HelpsYouRecallBoldLabel1", comment: "Helps you remember")
        let labelTwoLocalizedText = NSLocalizedString("HelpsYouRecallLabel2", comment: "Notifies you quickly if you’ve been exposed to COVID-19, to protect you and your loved ones")
        let labelTwoLocalizedBoldText = NSLocalizedString("HelpsYouRecallBoldLabel2", comment: "Notifies you quickly")
        labelOne.attributedText =  NSMutableAttributedString().attributedText(withString: labelOneLocalizedText, boldString: labelOneLocalizedBoldText)

        labelTwo.attributedText =  NSMutableAttributedString().attributedText(withString: labelTwoLocalizedText, boldString: labelTwoLocalizedBoldText)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AnalyticManager.setScreenName(screenName: "OnboardHowItWork", screenClass: "HelpsYouRecallViewController")
    }

    @IBAction func backPress(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}
