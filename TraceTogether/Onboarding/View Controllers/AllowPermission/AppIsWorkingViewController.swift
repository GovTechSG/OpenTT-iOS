//
//  AppIsWorkingViewController.swift
//  OpenTraceTogether

import UIKit
import SwiftyGif

class AppIsWorkingViewController: UIViewController {
    @IBOutlet weak var detailsLabel: UILabel!
    @IBOutlet weak var iphoneBackgroundingGif: UIImageView!
    @IBOutlet weak var headerTitlelabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        if SafeEntryUtils.isPassportUser() {
            headerTitlelabel.text = NSLocalizedString("AppActiveHeader", comment: "Your app is now activated!")
       } else {
            headerTitlelabel.text = NSLocalizedString("AppIsWorkingHeader", comment: "Your app is working now!")
       }

        do {
            let gif = try UIImage(gifName: "iphone_backgrounding.gif")
            self.iphoneBackgroundingGif.setGifImage(gif, loopCount: -1) // Will loop forever
        } catch {
            print("Could not find gif. \(error)")
        }

        var multiBoldDict = [String: String]()
        let localizedDetails = NSLocalizedString("PleaseNoteDetails", comment: "Remember to keep Bluetooth on, and keep your app open in the background (yes, we can work in iOS background now!)")
        let bold1Details = NSLocalizedString("PleaseNoteBold1Details", comment: "keep Bluetooth on")
        let bold2Details = NSLocalizedString("PleaseNoteBold2Details", comment: "keep your app open in the background")
        multiBoldDict[bold1Details] = bold1Details
        multiBoldDict[bold2Details] = bold2Details
        detailsLabel.attributedText = NSMutableAttributedString().attributedText(withString: localizedDetails, multiBoldDict: multiBoldDict)
        detailsLabel.setLineHeight(lineHeight: 5.0)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AnalyticManager.setScreenName(screenName: "OnBoardCompleted", screenClass: "AppIsWorkingViewController")
    }

    @IBAction func continueButtonClicked(_ sender: Any) {

        self.performSegue(withIdentifier: "showMain", sender: nil)
    }

}
