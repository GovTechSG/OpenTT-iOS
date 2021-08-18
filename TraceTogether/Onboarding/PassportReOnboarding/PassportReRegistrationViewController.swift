//
//  PassportReRegistrationViewController.swift
//  OpenTraceTogether

import UIKit
import SafariServices

class PassportReRegistrationViewController: UIViewController {

    @IBOutlet weak var partOneLabel: UILabel!
    @IBOutlet weak var partTwoLabel: UILabel!
    @IBOutlet weak var separatorLineImage: UIImageView!
    @IBOutlet weak var seeLessButton: UIButton!
    @IBOutlet weak var moreDetailsButton: UIButton!
    @IBOutlet weak var detailedInfoStackView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        showLess(nil)
    }

    @IBAction func helpButtonAction(_ sender: Any) {
        let vc = SFSafariViewController(url: URL(string: "https://support.tracetogether.gov.sg/hc/en-sg/articles/360058601893-Why-can-t-I-use-the-SafeEntry-feature-in-my-app-")!)
        present(vc, animated: true)
    }

    @IBAction func showLess(_ sender: UIButton?) {
        partOneLabel.attributedText = nil
        partTwoLabel.attributedText = nil
        separatorLineImage.isHidden = true
        detailedInfoStackView.backgroundColor = .clear
        detailedInfoStackView.isHidden = true
        moreDetailsButton.isHidden = false
        moreDetailsButton.layoutIfNeeded()
    }

    @IBAction func showMore(_ sender: UIButton?) {
        partOneLabel.attributedText = Markup.getAttributedString(markupString: NSLocalizedString("IfYouHaveOneofTheFollowing", comment: ""), font: UIFont.systemFont(ofSize: 16))
        partTwoLabel.attributedText = Markup.getAttributedString(markupString: NSLocalizedString("IfYourProfileFalls", comment: ""), font: UIFont.systemFont(ofSize: 16))
        separatorLineImage.isHidden = false
        detailedInfoStackView.backgroundColor = UIColor(hexString: "f2f2f2")
        detailedInfoStackView.isHidden = false
        moreDetailsButton.isHidden = true
    }

    @IBAction func reRegisterAction(_ sender: Any) {
        AnalyticManager.logEvent(eventName: "ppflow2_reRegisterAction", param: nil)

        let proceedAction = UIAlertAction(title: "Proceed", style: .default, handler: { _ in
            self.dismiss(animated: true, completion: nil)
            CoreDataHelper.deleteAllRecords()
            OnboardingManager.shared.startOver()
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        let title = NSLocalizedString("ProceedWithReRegistration", comment: "Proceed with re-registration?")
        let message = NSLocalizedString("SettingNewProfileErasingPreviousAppData", comment: "You'll be setting up a new profile. Your previous app data will be erased. Do NOT proceed if you are a traveller who left Singapore within the last 14 days.")
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(proceedAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true)
    }

}
