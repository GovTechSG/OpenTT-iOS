//
//  LTVPModalViewController.swift
//  OpenTraceTogether

import Foundation
import UIKit

class LTVPModalViewController: UIViewController {
    @IBOutlet weak var detailsLabel: UILabel!
    @IBOutlet weak var backLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        var underlineStrings = [String]()
        underlineStrings.append(NSLocalizedString("backOfNRICUnderline", comment: "back"))

        let detailsLocalized = NSLocalizedString("checkBackOfLTVP", comment: "Long Term Visit Pass")
        detailsLabel.attributedText = NSMutableAttributedString().attributedText(withString: detailsLocalized, boldString: detailsLocalized, underlineStrings: underlineStrings)

        backLabel.attributedText = NSMutableAttributedString().attributedText(withString: NSLocalizedString("backOfFIN", comment: "Back"), underlineString: NSLocalizedString("backOfFIN", comment: "Back"))
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AnalyticManager.setScreenName(screenName: "OnBoardLTVPInfo", screenClass: "LTVPModalViewController")
    }
    @IBAction func dismissModal(_ sender: Any) {
        dismiss(animated: true, completion: nil )
    }
}
