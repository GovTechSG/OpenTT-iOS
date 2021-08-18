//
//  Home_ViewController.swift
//  CurveView
//
//  OpenTraceTogether


import UIKit
import Firebase

class HomeViewController: UIViewController {

    var observers = [NSObjectProtocol]()

    @IBOutlet var subViewControllers: [UIViewController]!
    @IBOutlet var howLongKeepAppCard: UIView!

    @IBOutlet weak var howLongKeepAppCardLabel: UILabel!
    @IBOutlet weak var howLongKeepAppCardButton: UIButton!

    var heroViewController: HomeHeroViewController! {
        return subViewControllers.first { $0 is HomeHeroViewController } as? HomeHeroViewController
    }

    var appNotWorkingModal: AppNotWorkingModalVC? = AppNotWorkingModalVC()
    var turnOnBluetoothModal: TurnOnBluetoothModalVC? = TurnOnBluetoothModalVC()

    @IBOutlet weak var shareCardLabel: UILabel!
    @IBOutlet weak var shareCardButton: UIButton!

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        observers.append(NotificationCenter.default.addObserver(forName: .bluetoothStateDidChange, object: nil, queue: OperationQueue.main) {
            [unowned self] _ in
            self.considerBlockingHomePageAndUpdateGradient()
        })
        observers.append(NotificationCenter.default.addObserver(forName: .pnPermissionsDidChange, object: nil, queue: OperationQueue.main) {
            [unowned self] _ in
            self.considerBlockingHomePageAndUpdateGradient()
        })
        observers.append(NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: OperationQueue.main) {
            [unowned self] _ in
            self.considerBlockingHomePageAndUpdateGradient()
        })

        BlueTraceLocalNotifications.shared.requestAuthorization()
        BluetraceManager.shared.turnOn()
    }

    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        subViewControllers.forEach { c in
            addChild(c)
            c.viewDidLoad()
        }

        shareCardButton.accessibilityLabel = shareCardLabel.text

        self.definesPresentationContext = true

        turnOnBluetoothModal!.modalPresentationStyle = .overFullScreen
        turnOnBluetoothModal!.modalTransitionStyle = .crossDissolve
        appNotWorkingModal!.modalPresentationStyle = .overFullScreen
        appNotWorkingModal!.modalTransitionStyle = .crossDissolve
        // To put here till changes are finalized to onboarding
        InstanceID.instanceID().instanceID { (result, error) in
            if let error = error {
                print("Error fetching remote instance ID: \(error)")
                LogMessage.create(type: .Error, title: #function, details: "Error fetching remote instance ID: \(error)")
            } else if let result = result {
                print("Remote instance ID token: \(result.token)")
                UserDefaults.standard.set(result.token, forKey: FirebaseCloudMessaging.shared.fcmTokenKey)
                FirebaseAPIs.registerFCMToken { (success) in
                    print(success != nil ? "Token registered from Instance ID" : "Token failed to register")
                    LogMessage.create(type: .Error, title: #function, details: success != nil ? "Token registered from Instance ID" : "Token failed to register")
                    // Subscribe to HeartBeat topic
                    DispatchQueue.main.async {
                        Messaging.messaging().subscribe(toTopic: "heartbeat") { error in
                            if let err = error {
                                print(err)
                                LogMessage.create(type: .Error, title: #function, details: "Error subscribing to heartbeat: \(err.localizedDescription)")
                            }
                            print("Subscribed to heartbeat topic")
                            LogMessage.create(type: .Info, title: #function, details: "Subscribed to heartbeat topic")
                        }
                    }
                }
            }
        }

        SafeEntryUtils.setupSEQuickAction()
        showPassportUserHowLongCardIfRequired()
        howLongKeepAppCardButton.accessibilityLabel = howLongKeepAppCardLabel.text
    }

    func startOverIfTTIDNotMatchUID() {
        guard let ttId = UserDefaults.standard.string(forKey: "ttId"),
              let uid = FirebaseAPIs.currentUserId,
              ttId.starts(with: uid) else {
            return OnboardingManager.shared.showAlertAndStartOver(self)
        }
    }

    func showPassportUserHowLongCardIfRequired() {
        if SafeEntryUtils.isPassportUser() && UserDefaults.standard.bool(forKey: "PassportVerificationStatus") == true {
            howLongKeepAppCard.isHidden = false
        } else {
            howLongKeepAppCard.isHidden = true
            //howLongKeepAppCard.removeFromSuperview()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        LogMessage.create(type: .Info, title: #function, details: "", debugMessage: #function)
        super.viewDidAppear(animated)
        AnalyticManager.setScreenName(screenName: "HomePage", screenClass: "Home_ViewController")
        considerBlockingHomePageAndUpdateGradient()
        startOverIfTTIDNotMatchUID()
    }

    @IBAction func shareApp() {
        AnalyticManager.logEvent(eventName: "tap_share_app", param: ["position": "home_page_cards"])
        let shareText = NSLocalizedString("ShareApp", comment: "ShareApp")
        let activity = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        activity.popoverPresentationController?.sourceView = self.view
        present(activity, animated: true, completion: nil)
    }

    @IBAction func howLongKeepAppAction() {
        AnalyticManager.logEvent(eventName: "howLongKeepAppAction", param: ["position": "home_page_cards"])
        let commonOverlayViewController = UIStoryboard(name: "Home", bundle: nil).instantiateViewController(withIdentifier: "CommonOverlayViewController") as! CommonOverlayViewController
        commonOverlayViewController.modalPresentationStyle = .overFullScreen
        commonOverlayViewController.modalTransitionStyle = .crossDissolve
        let topModal = self.presentedViewController
        topModal?.dismiss(animated: false, completion: nil)
        present(commonOverlayViewController, animated: false) {
            commonOverlayViewController.setContent(Markup.getAttributedString(markupString: NSLocalizedString("PleaseKeepAppFor", comment: "PleaseKeepAppFor"), font: UIFont.systemFont(ofSize: 16)))
        }
    }

    ////////////////////////////////////////////////////////////////

    // MARK: Private functions

    ////////////////////////////////////////////////////////////////

    func considerBlockingHomePageAndUpdateGradient() {
        guard isViewLoaded else {
            return
        }

        let isBluetoothOn = PermissionsUtils.isBluetoothOn() && !PermissionsUtils.isBluetoothResettingOrUnknown()
        let isAllPermissionsAuthorized = PermissionsUtils.isAllPermissionsAuthorized()
        let topModal = self.presentedViewController

        appNotWorkingModal?.displayMissingAuthorizations()

        LogMessage.create(type: .Info, title: "\(#function)", details:
                            ["isAllPermissionsAuthorized": "\(PermissionsUtils.isAllPermissionsAuthorized())",
                             "isBluetoothAuthorized": "\(PermissionsUtils.isBluetoothAuthorized())",
                             "isPushNotificationsAuthorised": "\(PermissionsUtils.isPushNotificationsAuthorised())",
                             "isBluetoothOn": "\(PermissionsUtils.isBluetoothOn())",
                             "topModal": "\(String(describing: topModal.self))"], collectable: true)

        if topModal == nil {
            if isBluetoothOn && isAllPermissionsAuthorized {
                heroViewController?.play()
            } else if !isAllPermissionsAuthorized {
                heroViewController?.stop()
                present(appNotWorkingModal!, animated: false)
                appNotWorkingModal?.displayMissingAuthorizations()
            } else if !isBluetoothOn {
                heroViewController?.stop()
                present(turnOnBluetoothModal!, animated: false)
            }
        } else if topModal == appNotWorkingModal {
            if isBluetoothOn && isAllPermissionsAuthorized {
                topModal?.dismiss(animated: false, completion: nil)
                heroViewController?.play()
            } else if !isBluetoothOn && isAllPermissionsAuthorized {
                topModal?.dismiss(animated: false, completion: nil)
                present(turnOnBluetoothModal!, animated: false)
            }
        } else if topModal == turnOnBluetoothModal {
            if isBluetoothOn && isAllPermissionsAuthorized {
                topModal?.dismiss(animated: false, completion: nil)
                heroViewController?.play()
            } else if !isAllPermissionsAuthorized {
                topModal?.dismiss(animated: false, completion: nil)
                present(appNotWorkingModal!, animated: false)
            }
        }
    }
}
