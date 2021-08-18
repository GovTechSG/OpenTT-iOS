//
//  OtherPassportModalViewController.swift
//  OpenTraceTogether

import Foundation
import UIKit

class OtherPassportModalViewController: UIViewController {

    @IBOutlet weak var detailsLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        var underlineStrings = [String]()
        underlineStrings.append(NSLocalizedString("backOfNRICUnderline", comment: "back"))

        let detailsLocalized = NSLocalizedString("checkBackOfWorkPass", comment: "Check the back of your card for Date of Issue")
        detailsLabel.attributedText = NSMutableAttributedString().attributedText(withString: detailsLocalized, boldString: detailsLocalized, underlineStrings: underlineStrings)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AnalyticManager.setScreenName(screenName: "OnBoardSTPLTVPPInfo", screenClass: "OtherPassportModalViewController")
    }
    @IBAction func dismissModal(_ sender: Any) {
        dismiss(animated: true, completion: nil )
    }
}
