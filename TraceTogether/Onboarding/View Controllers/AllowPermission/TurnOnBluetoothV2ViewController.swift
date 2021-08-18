//
//  TurnOnBluetoothV2ViewController.swift
//  OpenTraceTogether

import UIKit
import FirebaseAnalytics

class TurnOnBluetoothV2ViewController: UIViewController {
    var observers = [NSObjectProtocol]()
    @IBOutlet weak var detailsLabel: UILabel!

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        observers.append(NotificationCenter.default.addObserver(forName: .bluetoothStateDidChange, object: nil, queue: OperationQueue.main) {
            [unowned self] _ in
            self.checkBluetoothStatus()
        })
      }

    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    @IBOutlet weak var nextButton: UIButton!
    private var observer: Any!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        nextButton.setBackgroundColor(color: UIColor(hexString: "#F2F2F2"), forState: .disabled)
        nextButton.setTitleColor(UIColor(hexString: "#BDBDBD"), for: .disabled)
        checkBluetoothStatus()

        let localizedText = NSLocalizedString("GoToSettingsTurnOnBluetooth", comment: "Go to Settings or Control Center and turn on your phone’s Bluetooth. \n\nThen come back to the app.")
        let localizedToBold1 = NSLocalizedString("Settings", comment: "Settings")
        let localizedToBold2 = NSLocalizedString("ControlCenter", comment: "Control Center")

        var multiBoldDict = [String: String]()
        multiBoldDict[localizedToBold1] = localizedToBold1
        multiBoldDict[localizedToBold2] = localizedToBold2
        detailsLabel.attributedText = NSMutableAttributedString().attributedText(withString: localizedText, multiBoldDict: multiBoldDict)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AnalyticManager.setScreenName(screenName: "OnboardTurnOnBluetooth", screenClass: "TurnOnBluetoothViewController")
    }

    func checkBluetoothStatus() {
        LogMessage.create(type: .Info, title: "\(#function)", details:
                            ["isBluetoothOn": "\(BluetraceManager.shared.isBluetoothOn())",
                             "isBluetoothAuthorized": "\(BluetraceManager.shared.isBluetoothAuthorized())",
                             "isAllPermissionsAuthorized": "\(PermissionsUtils.isAllPermissionsAuthorized())",
                             "isBluetoothAuthorizationNotDetermined": "\(BluetraceManager.shared.isBluetoothAuthorizationNotDetermined())"],
                          collectable: true)

        let bleAuthorized = BluetraceManager.shared.isBluetoothAuthorized()
        let blePoweredOn = BluetraceManager.shared.isBluetoothOn()

        if FormRegisterPassportProfileController().tempPassportData != nil {
            showPassportHoldingScreen()
            return
        }
        // if Bluetooth is not authorised, we will not be able to tell if it is turned on
        if !bleAuthorized {
            self.performSegue(withIdentifier: "showMain", sender: self)
        } else if blePoweredOn {
            if PermissionsUtils.isAllPermissionsAuthorized() {
                if (self.navigationController?.topViewController as? AppIsWorkingViewController) == nil {
                    self.performSegue(withIdentifier: "showAppWorking", sender: self)
                }
            } else {
                self.performSegue(withIdentifier: "showMain", sender: self)
            }
        }
    }

    func showPassportHoldingScreen() {
        let passportHoldingVC = UIStoryboard(name: "PassportHolding", bundle: nil).instantiateInitialViewController()!
        navigationController!.setViewControllers([passportHoldingVC], animated: true)
    }
}
