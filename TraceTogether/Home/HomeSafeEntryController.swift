//
//  HomeSafeEntryController.swift
//  OpenTraceTogether

import UIKit
import CoreData
import SafariServices

class HomeSafeEntryController: SafeEntryBaseViewController, HomeShortcutSiriDelegate, HomeShortcutQuickLaunchDelegate, HomeShortcutWidgetDelegate, NetworkIssuesDelegate {
    lazy var networkIssueScreen = UIStoryboard(name: "PassportReOnboarding", bundle: nil).instantiateViewController(withIdentifier: "InternetUnavailableViewController") as! InternetUnavailableViewController
    lazy var serverDownScreen = UIStoryboard(name: "PassportReOnboarding", bundle: nil).instantiateViewController(withIdentifier: "ServerDownViewController") as! ServerDownViewController
    var reachability: Reachability {
         let appDelegate = UIApplication.shared.delegate as! AppDelegate
         return appDelegate.reachability!
    }

    @IBOutlet var checkInCard: UIButton!
    @IBOutlet var checkOutButton: LoadingButton!
    @IBOutlet var venueLabel: UILabel!
    @IBOutlet var checkInView: UIView!
    @IBOutlet var safeEntryOptionsCard: UIView!
    @IBOutlet var safeEntryDisabledCard: UIView!
    @IBOutlet var errorDecryptingCard: UIView!
    @IBOutlet var checkInImage: UIImageView!
    @IBOutlet var checkInTitle: UILabel!
    @IBOutlet var exclamationImage: UIImageView!

    var shortcutSiriViewModel = HomeShortcutSiriViewModel()
    var shortcutQuickLaunchViewModel = HomeShortcutQuickLaunchViewModel()
    var shortcutWidgetViewModel = HomeShortcutWidgetViewModel()

    var canPerformSafeEntry: Bool {
        LogMessage.create(type: .Info, title: "HomeSafeEntryController.canPerformSafeEntry", details:
                            ["isAllPermissionsAuthorized": "\(PermissionsUtils.isAllPermissionsAuthorized())",
                             "isBluetoothAuthorized": "\(PermissionsUtils.isBluetoothAuthorized())",
                             "isPushNotificationsAuthorised": "\(PermissionsUtils.isPushNotificationsAuthorised())",
                             "isBluetoothOn": "\(PermissionsUtils.isBluetoothOn())",
                             "isUserAllowedToSafeEntry": "\(SafeEntryUtils.isUserAllowedToSafeEntry())"], collectable: true)
        return SafeEntryUtils.isUserAllowedToSafeEntry() &&
            PermissionsUtils.isAllPermissionsAuthorized() &&
            PermissionsUtils.isBluetoothOn()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        networkIssueScreen.userDelegate = self
        serverDownScreen.userDelegate = self

        shortcutSiriViewModel.delegate = self
        shortcutSiriViewModel.viewDidLoad()

        shortcutQuickLaunchViewModel.delegate = self
        shortcutQuickLaunchViewModel.viewDidLoad()

        shortcutWidgetViewModel.delegate = self
        shortcutWidgetViewModel.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(reloadView), name: UIApplication.willEnterForegroundNotification, object: nil)
        checkIfPassportUserRequiresReregistration()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadView()
        shortcutSiriViewModel.viewDidAppear()
        shortcutQuickLaunchViewModel.viewDidAppear()
        shortcutWidgetViewModel.viewDidAppear()
        AnalyticManager.setScreenName(screenName: "HomeSafeEntryController", screenClass: "HomeSafeEntryController")
    }

    @objc func reloadView() {
        if OnboardingManager.shared.hasUserID && OnboardingManager.shared.hasCurrentUser && OnboardingManager.shared.hasTtId {
            if SafeEntryUtils.isUserAllowedToSafeEntry() == false {
                self.showSEDisabledView()
            } else {
                showSafeEntryOptionsCard()
            }
        } else {
            showErrorDecryptingCard()
        }
    }

    func retryAction() {
        checkIfPassportUserRequiresReregistration()
    }

    func checkIfPassportUserRequiresReregistration() {
        if SafeEntryUtils.isUserAllowedToSafeEntry() == true {
            return
        }

        let topModal = self.presentedViewController
        topModal?.dismiss(animated: false, completion: nil)
        LoadingViewController.present(in: self) {
            if self.reachability.connection == .unavailable {
                LoadingViewController.dismiss(in: self) {[weak self] in
                    self?.showNetworkIssueView()
                }
            } else {
                FirebaseAPIs.getPassportStatus {[weak self] (status, error) in
                    guard let self = self else {
                        return
                    }
                    LoadingViewController.dismiss(in: self) {
                        if error != nil {
                            LogMessage.create(type: .Error, title: #function, details: "Cloud function error, \(String(describing: error))")
                            self.showServerDownView()
                            return
                        }
                        if status == false {
                            self.showSEDisabledView()
                            return
                        }
                        UserDefaults.standard.setValue(true, forKey: "PassportVerificationStatus")
                        self.showSafeEntryOptionsCard()
                    }
                }
            }
        }
    }

    @IBAction func scanQR() {
        AnalyticManager.logEvent(eventName: "se_tap_scan_qr", param: ["position": "se_section"])
        goToScanQR()
    }

    @IBAction func favouritesCheckIn() {
        AnalyticManager.logEvent(eventName: "se_tap_favourites_check_in", param: ["position": "se_section"])
        goToFavourites()
    }

    @IBAction func groupCheckIn() {
        AnalyticManager.logEvent(eventName: "se_tap_group_check_in", param: ["position": "se_section"])
        goToGroupCheckIn()
    }

    @IBAction func viewPass(_ sender: LoadingButton) {
        AnalyticManager.logEvent(eventName: "se_tap_view_pass", param: ["position": "se_section"])
        viewPass()
    }

    @IBAction func checkOut(_ sender: LoadingButton) {
        AnalyticManager.logEvent(eventName: "se_tap_check_out", param: ["position": "se_section"])
        checkOut()
    }

    @IBAction func checkEligibility() {
        AnalyticManager.logEvent(eventName: "se_tap_check_eligibility", param: ["position": "se_section"])
        let vc = SFSafariViewController(url: URL(string: "https://support.tracetogether.gov.sg/hc/en-sg/articles/360058601893-Why-can-t-I-use-the-SafeEntry-feature-in-my-app-")!)
        present(vc, animated: true)
    }

    @IBAction func reRegister(_ sender: UIButton) {
        AnalyticManager.logEvent(eventName: "se_tap_re_register", param: ["position": "se_section"])

        let proceedAction = UIAlertAction(title: "Proceed", style: .default, handler: { _ in
            self.dismiss(animated: true, completion: nil)
            CoreDataHelper.deleteAllRecords()
            OnboardingManager.shared.startOver()
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        let title = NSLocalizedString("ProceedWithReRegistration", comment: "Proceed with re-registration?")
        let message = sender.tag == 0 ? NSLocalizedString("OnlyProceedIfInSingapore", comment: "<b>Only proceed if you're currently in Singapore.</b> Proceeding will set up a new profile upon registration, and your previous app data will be erased.") : NSLocalizedString("SettingNewProfileErasingPreviousAppData", comment: "You'll be setting up a new profile. Your previous app data will be erased. Do NOT proceed if you are a traveller who left Singapore within the last 14 days.")
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(proceedAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true)
    }

    func showSEDisabledView() {
        hideAllViews()
        showCheckInDisabled()
        safeEntryDisabledCard.isHidden = false
        safeEntryDisabledCard.layoutIfNeeded()
    }

    func showErrorDecryptingCard() {
        hideAllViews()
        showCheckInDisabled()
        errorDecryptingCard.isHidden = false
        errorDecryptingCard.layoutIfNeeded()
    }

    func showSafeEntryOptionsCard() {
        hideAllViews()
        showCheckInEnabled()
        safeEntryOptionsCard.isHidden = false
        checkInView.isHidden = lastSafeEntrySessionWithoutCheckout == nil

        let tenantName = lastSafeEntrySessionWithoutCheckout?.tenantName
        let venueName = lastSafeEntrySessionWithoutCheckout?.venueName
        venueLabel.text = SafeEntryUtils.formatSETenantVenueDisplay(tenantName, venueName)
    }

    func hideAllViews() {
        errorDecryptingCard.isHidden = true
        safeEntryDisabledCard.isHidden = true
        safeEntryOptionsCard.isHidden = true
        checkInView.isHidden = true
    }

    func showCheckInDisabled() {
        checkInImage.alpha = 0.5
        checkInTitle.alpha = 0.5
        exclamationImage.isHidden = false
    }

    func showCheckInEnabled() {
        checkInImage.alpha = 1.0
        checkInTitle.alpha = 1.0
        exclamationImage.isHidden = true
    }

    func showNetworkIssueView() {
        networkIssueScreen.modalPresentationStyle = .overFullScreen
        networkIssueScreen.modalTransitionStyle = .crossDissolve
        let topModal = self.presentedViewController
        topModal?.dismiss(animated: false, completion: nil)
        present(networkIssueScreen, animated: false)
    }

    func showServerDownView() {
        serverDownScreen.modalPresentationStyle = .overFullScreen
        serverDownScreen.modalTransitionStyle = .crossDissolve
        let topModal = self.presentedViewController
        topModal?.dismiss(animated: false, completion: nil)
        present(serverDownScreen, animated: false)
    }

    func viewPass() {
        guard canPerformSafeEntry,
              let currentVenueName = lastSafeEntrySessionWithoutCheckout?.venueName,
              let currentTenantName = lastSafeEntrySessionWithoutCheckout?.tenantName,
              let currentCheckInDate = lastSafeEntrySessionWithoutCheckout?.checkInDate else {
            return
        }

        // Do not view pass if it's already viewing
        let checkInOutVC = presentedViewController?.children.first as? CheckInOutViewController
        guard (checkInOutVC == nil || checkInOutVC!.safeEntryCheckInOutDisplayModel.VIEWEDCHECKOUTPASS) else {
            return
        }

        presentedViewController?.dismiss(animated: false, completion: nil)

        safeEntryCheckInOutDisplayModel.VENUENAME = SafeEntryUtils.formatSETenantVenueDisplay(currentTenantName, currentVenueName).uppercased()

        safeEntryCheckInOutDisplayModel.CHECKINDATE = SafeEntryUtils.getDateStringForCheckInOutViewDisplay(currentCheckInDate)
        safeEntryCheckInOutDisplayModel.CHECKINTIME = SafeEntryUtils.getTimeStringForCheckInOutViewDisplay(currentCheckInDate)
        safeEntryCheckInOutDisplayModel.VIEWEDCHECKINPASS = false
        safeEntryCheckInOutDisplayModel.VIEWEDCHECKOUTPASS = false
        safeEntryCheckInOutDisplayModel.NUMBEROFPERONCHECKING = (lastSafeEntrySessionWithoutCheckout?.groupIDs?.count ?? 0) + 1
        safeEntryCheckInOutDisplayModel.tenantID = lastSafeEntrySessionWithoutCheckout?.tenantId ?? ""
        safeEntryCheckInOutDisplayModel.venueID = lastSafeEntrySessionWithoutCheckout?.venueId ?? ""
        DispatchQueue.main.async {
            self.goToCheckInOutVC()
        }
    }

    func checkOut() {
        guard canPerformSafeEntry,
              lastSafeEntrySessionWithoutCheckout != nil else {
            return
        }
        presentedViewController?.dismiss(animated: false, completion: nil)

        safeEntryCheckInOutDisplayModel.VIEWEDCHECKINPASS = false
        safeEntryCheckInOutDisplayModel.VIEWEDCHECKOUTPASS = true

        super.invokeCheckOutAPI(checkOutButton) {_ in
            print("Navigate to checkInOut VC")
            DispatchQueue.main.async {
                self.goToCheckInOutVC()
            }
        }
    }

    func goToScanQR() {
        guard canPerformSafeEntry else {
            return
        }
        presentedViewController?.dismiss(animated: false, completion: nil)
        let storyboard = UIStoryboard(name: "SafeEntry", bundle: nil)
        let tabbarVC = storyboard.instantiateViewController(withIdentifier: "SafeEntryFlow") as! SafeEntryTabBarController
        self.present(tabbarVC, animated: false, completion: nil)
    }

    func goToFavourites() {
        guard canPerformSafeEntry else {
            return
        }
        presentedViewController?.dismiss(animated: false, completion: nil)

        let storyboard = UIStoryboard(name: "SafeEntry", bundle: nil)
        let tabbarVC = storyboard.instantiateViewController(withIdentifier: "SafeEntryFlow") as! UITabBarController
        tabbarVC.selectedIndex = 1
        self.present(tabbarVC, animated: true, completion: nil)
    }

    func goToGroupCheckIn() {
        guard canPerformSafeEntry else {
            return
        }
        presentedViewController?.dismiss(animated: false, completion: nil)

        // Set as home screen first to present Group Check In
        self.navigationController?.tabBarController?.selectedIndex = 0

        let vc = UIStoryboard(name: "SettingsView", bundle: Bundle.main).instantiateViewController(withIdentifier: "FamilyMemberGroupCheckInViewController") as! FamilyMemberGroupCheckInViewController
        self.navigationController?.pushViewController(vc, animated: true)
        vc.didPresentSafeEntry = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
    }

    func goToCheckInOutVC() {
        guard canPerformSafeEntry else {
            return
        }
        presentedViewController?.dismiss(animated: false, completion: nil)

        let storyboard = UIStoryboard(name: "SafeEntry", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CheckInOutViewController") as! CheckInOutViewController
        vc.safeEntryCheckInOutDisplayModel = safeEntryCheckInOutDisplayModel
        let navigationController = UINavigationController(rootViewController: vc)
        navigationController.modalPresentationStyle = .fullScreen
        self.present(navigationController, animated: true, completion: nil)
    }
}
