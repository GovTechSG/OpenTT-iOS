//
//  ReonboardingWhatsNewViewController.swift
//  OpenTraceTogether

import UIKit
import SwiftyGif
import FirebaseAnalytics

class ReonboardingWhatsNewViewController: UIViewController {
    @IBOutlet weak var backgroundDesc: UILabel!
    @IBOutlet weak var languageDesc: UILabel!
    @IBOutlet weak var newLookDesc: UILabel!
    @IBOutlet weak var scanAndGoDesc: UILabel!
    @IBOutlet weak var idVerificationDesc: UILabel!
    @IBOutlet weak var whatYouNeedToDoDesc: UILabel!
    @IBOutlet weak var nextBtn: UIButton!
    @IBOutlet weak var iphoneBackgroundingGif: UIImageView!

    // Views for handling diff versions
    @IBOutlet weak var newLookView: UIView!
    @IBOutlet weak var scanAndGoView: UIView!

    // Check version here
    var showReonboarding = false

    override func viewDidLoad() {
        super.viewDidLoad()
        do {
            let gif = try UIImage(gifName: "iphone_backgrounding.gif")
            self.iphoneBackgroundingGif.setGifImage(gif, loopCount: -1) // Will loop forever
        } catch {
            print("Could not find gif. \(error)")
        }

        if !showReonboarding {
            newLookView.isHidden = true
            scanAndGoView.isHidden = true
            nextBtn.setTitle(NSLocalizedString("OKExclam", comment: "OK!"), for: .normal)
        }

        // Remove old pending notifs during reonboarding
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["appBackgroundNotifId"])
        BlueTraceLocalNotifications.shared.checkAuthorization() // to store pnPermissionsState in userDefaults

        let backgroundDescText = NSLocalizedString("iPhoneUsersBackgroundWorks", comment: "iPhone users — your app can work in the background now")
        let backgroundDescBoldText = NSLocalizedString("iPhoneUsersBackgroundBold", comment: "background")
        let whatYouNeedToDoText = NSLocalizedString("WhatYouNeedToDo", comment: "Keep your app open in the background. Do not swipe up on the app to close it.")
        let whatYouNeedToDoTextBold = NSLocalizedString("WhatYouNeedToDoBold", comment: "Keep your app open in the background")
        let languageDescText = NSLocalizedString("MoreLanguages", comment: "More languages — বাংলা, ဗမာ, 中文, हिन्दी, Melayu, தமிழ், ไทย")
        let languageDescBoldText = NSLocalizedString("Languages", comment: "languages")
        let newLookText = NSLocalizedString("NewLook", comment: "New look — from blue to red")
        let newLookboldText = NSLocalizedString("NewLookBold", comment: "New look")
        let scanAndGoDescText = NSLocalizedString("ScanAndGo", comment: "Scan and go with SafeEntry QR code — no more forms")
        let scanAndGoDescBoldText = NSLocalizedString("ScanAndGoBold", comment: "Scan and go")

        let verificationDescText  = NSLocalizedString("PersonalMedicalInformation", comment: "ID verification, so you can receive personal medical information related to COVID-19 through TraceTogether")
        let verificationBoldText = NSLocalizedString("IDVerification", comment: "ID verification")

        backgroundDesc.attributedText = NSMutableAttributedString().attributedText(withString: backgroundDescText, boldString: backgroundDescBoldText)
        whatYouNeedToDoDesc.attributedText = NSMutableAttributedString().attributedText(withString: whatYouNeedToDoText, boldString: whatYouNeedToDoTextBold)
        languageDesc.attributedText = NSMutableAttributedString().attributedText(withString: languageDescText, boldString: languageDescBoldText)
        newLookDesc.attributedText = NSMutableAttributedString().attributedText(withString: newLookText, boldString: newLookboldText)
        scanAndGoDesc.attributedText = NSMutableAttributedString().attributedText(withString: scanAndGoDescText, boldString: scanAndGoDescBoldText)
        idVerificationDesc.attributedText = NSMutableAttributedString().attributedText(withString: verificationDescText, boldString: verificationBoldText)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AnalyticManager.setScreenName(screenName: "ReOnboard", screenClass: "ReOnboardingViewController")
    }
    @IBAction func selectChangeLanguageClicked(_ sender: Any) {
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
    }
    @IBAction func goToNextScreenTapped(_ sender: Any) {
        if showReonboarding {
            self.performSegue(withIdentifier: "goToProfileScreenSegue", sender: self)
        } else {
            VersionNumberHelper.appVersionOnViewWhatsNew = VersionNumberHelper.getCurrentVersion()
            self.performSegue(withIdentifier: "goToMainSegue", sender: self)
        }
    }
}
