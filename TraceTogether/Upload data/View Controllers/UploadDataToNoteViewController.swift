//
//  UploadDataToNoteViewController.swift
//  OpenTraceTogether

import UIKit

class UploadDataToNoteViewController: UIViewController {
    @IBOutlet weak var safeEntryBtn: UIBarButtonItem!
    @IBOutlet weak var detailsLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        var underlineStrings = [String]()
        underlineStrings.append(NSLocalizedString("DidNot", comment: "did not"))
        underlineStrings.append(NSLocalizedString("DoNot", comment: "do not"))
        let uploadCodeLocalizedText = NSLocalizedString("UploadCodeOnlyGivenToPplCovid19", comment: "An upload code is only given to patients with COVID-19.\n\nIf you did not get an upload code from MOH, you do not need to upload data :)")
        detailsLabel.attributedText = NSMutableAttributedString().attributedText(withString: uploadCodeLocalizedText, boldString: NSLocalizedString("IfYouDidNotGetUploadCode", comment: "If you did not get an upload code from MOH, you do not need to upload data :)"), underlineStrings: underlineStrings)
        if !SafeEntryUtils.isUserAllowedToSafeEntry() {
            safeEntryBtn.isEnabled = false
            safeEntryBtn.image = nil
        }
        detailsLabel.accessibilityLabel =  uploadCodeLocalizedText.replacingOccurrences(of: "MOH", with: "M O H")
        safeEntryBtn.accessibilityLabel = NSLocalizedString("ScanQRCode", comment: "Scan the SafeEntry QR code")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AnalyticManager.setScreenName(screenName: "UploadMain", screenClass: "UploadDataToNoteViewController")
    }

    @IBAction func safeEntryButtonClicked(_ sender: Any) {
        let storyboard = UIStoryboard(name: "SafeEntry", bundle: nil)
        let tabbarVC = storyboard.instantiateViewController(withIdentifier: "SafeEntryFlow") as! SafeEntryTabBarController
        self.present(tabbarVC, animated: false, completion: nil)
    }
}
