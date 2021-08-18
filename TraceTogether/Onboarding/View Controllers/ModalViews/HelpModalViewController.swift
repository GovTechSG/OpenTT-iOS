//
//  HelpModalViewController.swift
//  OpenTraceTogether

import Foundation
import UIKit
import FirebaseAnalytics

class HelpModalViewController: UIViewController {

    @IBOutlet weak var detailsLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var gotItButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        let localizedText = NSLocalizedString("HelpModalDetailsMainText", comment: "Your unique identification number allows MOH to reach the right person when they need to give you important health advice about COVID-19.")
        let localizedToBold = NSLocalizedString("HelpModalDetailsMainBoldText", comment: "reach the right person")

        detailsLabel.attributedText = NSMutableAttributedString().attributedText(withString: localizedText, boldString: localizedToBold)

        detailsLabel.accessibilityLabel = localizedText.replacingOccurrences(of: "MOH", with: "M O H")
        closeButton.accessibilityLabel = NSLocalizedString("Close", comment: "Close")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.accessibilityViewIsModal = true
        gotItButton.titleLabel?.adjustsFontSizeToFitWidth = true

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AnalyticManager.setScreenName(screenName: "OnboardWhyDetails", screenClass: "HelpModalViewController")
    }
}
