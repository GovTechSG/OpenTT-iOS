//
//  NRICModalViewController.swift
//  OpenTraceTogether

import Foundation
import UIKit

class NRICModalViewController: UIViewController {

    @IBOutlet weak var detailsLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        AnalyticManager.setScreenName(screenName: "DateOfIssue", screenClass: "DateOfIssueViewController")

        let detailsLocalized = NSLocalizedString("backOfNRIC", comment: "At the back of your NRIC")
        let detailsUnderlinedLocalized = NSLocalizedString("backOfNRICUnderline", comment: "back")
        detailsLabel.attributedText = NSMutableAttributedString().attributedText(withString: detailsLocalized, underlineString: detailsUnderlinedLocalized)
    }
    override func viewDidAppear(_ animated: Bool) {
          super.viewDidAppear(animated)
          AnalyticManager.setScreenName(screenName: "OnBoardNRICInfo", screenClass: "NRICModalViewController")
      }
    @IBAction func dismissModal(_ sender: Any) {
        dismiss(animated: true, completion: nil )
    }
}
