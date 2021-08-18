//
//  IDViewController.swift
//  OpenTraceTogether

import Foundation
import RSBarcodes_Swift
import AVFoundation
import UIKit

class IDViewController: UIViewController {
    @IBOutlet weak var nricButton: UIButton!
    @IBOutlet weak var barcodeImageView: UIImageView!
    @IBOutlet weak var leadingProgressConstraint: NSLayoutConstraint!

    @IBOutlet weak var howToUseView: UIView!

    var originalBrightness: CGFloat = UIScreen.main.brightness
    var valueHidden = true {
        didSet {
            var id = credentials.password
            if (valueHidden) {
                id = NricFinMask.maskUserId(id)
            }
            nricButton.isSelected = !valueHidden
            nricButton.setTitle(id, for: .normal)
            nricButton.accessibilityLabel = NricFinMask.getAccessibilityLabel(id)
        }
    }

    /// The service we are accessing with the credentials.
    let service = "nricService"

    private var credentials = SecureStore.Credentials(username: "", password: "")
    var window = UIWindow()

    override func viewDidLoad() {
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        setupHowToUseAction()

        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        window = appDelegate.window!

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.didBecomeActiveNotification, object: nil)

        do {
            print("Reading credentials...")
            self.credentials = try SecureStore.readCredentials(service: service, accountName: "id")

            if let idType = UserDefaults.standard.string(forKey: "idType") {
                let profileType = NricFinChecker.checkIdType(idType: idType)
                /*
                 
                 barcodeImageView.image = <insert barcode generation logic here>
                 
                */
            }
        } catch {
            if let error = error as? SecureStore.KeychainError {
                if #available(iOS 11.3, *) {
                    LogMessage.create(type: .Error, title: #function, details: "KeychainError: \(error.localizedDescription)", debugMessage: "KeychainError: \(error.localizedDescription)")
                } else {
                    LogMessage.create(type: .Error, title: #function, details: "KeychainError: \(error)", debugMessage: "KeychainError: \(error)")
                }
            }
            OnboardingManager.shared.showAlertAndStartOver(self)
        }
        valueHidden = true
        leadingProgressConstraint.constant = (UIScreen.main.bounds.width/3) * 2
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
         AnalyticManager.setScreenName(screenName: "SEDisplayBarcode", screenClass: "IDViewController")
    }

    @objc func appMovedToBackground() {
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = window.frame
        blurEffectView.tag = 100
        UIScreen.main.setBrightness(to: originalBrightness)
        window.addSubview(blurEffectView)
    }

    @objc func appMovedToForeground() {
        window.viewWithTag(100)?.removeFromSuperview()
        UIScreen.main.setBrightness(to: 1.0)
    }

    @IBAction func toggleVisi(_ sender: UIButton) {
        valueHidden = !valueHidden
    }

    func setupHowToUseAction() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(goToHelpView))
        tapGestureRecognizer.numberOfTapsRequired = 1
        self.howToUseView.addGestureRecognizer(tapGestureRecognizer)
    }

    @objc func goToHelpView(recognizer: UITapGestureRecognizer) {
        self.showIDScanInstructions()
    }

    func showIDScanInstructions() {
        let storyboard = UIStoryboard(name: "SafeEntry", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "QRInstructionsViewController") as! UINavigationController
        vc.modalPresentationStyle = .fullScreen
        vc.modalTransitionStyle = .crossDissolve
        UserDefaults.standard.setValue(false, forKey: "groupCheckInFlowToHandleHowToUse")
        self.present(vc, animated: true, completion: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        UIScreen.main.setBrightness(to: 1.0)
    }

    override func viewWillDisappear(_ animated: Bool) {
        UIScreen.main.setBrightness(to: originalBrightness)
    }

    @IBAction func returnToMainPage() {
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
}
