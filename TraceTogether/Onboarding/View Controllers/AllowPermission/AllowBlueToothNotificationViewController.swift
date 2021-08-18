//
//  AllowBlueToothNotificationViewController.swift
//  OpenTraceTogether

import UIKit

class AllowBlueToothNotificationViewController: UIViewController {

    @IBOutlet weak var nextButton: UIButton!
    var observers = [NSObjectProtocol]()
    var isBluetoothDialogOver = false
    var isPNDialogOver = false

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        observers.append(NotificationCenter.default.addObserver(forName: .bluetoothStateDidChange, object: nil, queue: OperationQueue.main) {
            [unowned self] _ in
            self.checkBluetoothDialogOver()
        })
        observers.append(NotificationCenter.default.addObserver(forName: .pnPermissionsDidChange, object: nil, queue: OperationQueue.main) {
            [unowned self] _ in
            self.checkPNDialogOver()
        })

    }

    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AnalyticManager.setScreenName(screenName: "OnBoardBTPermission", screenClass: "AllowBlueToothNotificationViewController")
        LogMessage.create(type: .Info, title: "\(#function)", details:
                            ["isBluetoothOn": "\(BluetraceManager.shared.isBluetoothOn())",
                             "isBluetoothAuthorized": "\(BluetraceManager.shared.isBluetoothAuthorized())",
                             "isBluetoothAuthorizationNotDetermined": "\(BluetraceManager.shared.isBluetoothAuthorizationNotDetermined())"],
                          collectable: true)
    }

    @IBAction func allowButtonClicked(_ sender: Any) {
        LogMessage.create(type: .Info, title: "\(#function)", details:
                            ["isBluetoothOn": "\(BluetraceManager.shared.isBluetoothOn())",
                             "isBluetoothAuthorized": "\(BluetraceManager.shared.isBluetoothAuthorized())",
                             "isBluetoothAuthorizationNotDetermined": "\(BluetraceManager.shared.isBluetoothAuthorizationNotDetermined())",
                             "nextButton.isEnabled": "\(nextButton.isEnabled)"],
                          collectable: true)
        nextButton.isEnabled = false
        BluetraceManager.shared.turnOn()
        checkBluetoothDialogOver() // fallback call in case usernotification isnt received, e.g. if authorization has already been granted
    }

    func checkBluetoothDialogOver() {
        LogMessage.create(type: .Info, title: "\(#function)", details:
                            ["isBluetoothOn": "\(BluetraceManager.shared.isBluetoothOn())",
                             "isBluetoothAuthorized": "\(BluetraceManager.shared.isBluetoothAuthorized())",
                             "isBluetoothAuthorizationNotDetermined": "\(BluetraceManager.shared.isBluetoothAuthorizationNotDetermined())",
                             "nextButton.isEnabled": "\(nextButton.isEnabled)"],
                          collectable: true)

        if !BluetraceManager.shared.isBluetoothAuthorizationNotDetermined() && !isBluetoothDialogOver {
            isBluetoothDialogOver = true
            BlueTraceLocalNotifications.shared.requestAuthorization()
            checkPNDialogOver()  // fallback call in case usernotification isnt received, e.g. if authorization has already been granted
        }
    }

    func checkPNDialogOver() {
        LogMessage.create(type: .Info, title: "\(#function)", details:
                            ["isBluetoothOn": "\(BluetraceManager.shared.isBluetoothOn())",
                             "isBluetoothAuthorized": "\(BluetraceManager.shared.isBluetoothAuthorized())",
                             "isBluetoothAuthorizationNotDetermined": "\(BluetraceManager.shared.isBluetoothAuthorizationNotDetermined())",
                             "nextButton.isEnabled": "\(nextButton.isEnabled)"],
                          collectable: true)

        if !BlueTraceLocalNotifications.shared.isPNAuthorizationNotDetermined() && !isPNDialogOver {
            isPNDialogOver = true
            OnboardingManager.shared.allowedBluetoothPermissions = true

            if BluetraceManager.shared.isBluetoothOn() {
                if FormRegisterPassportProfileController().tempPassportData != nil {
                    showPassportHoldingScreen()
                } else if PermissionsUtils.isAllPermissionsAuthorized() {
                    if (self.navigationController?.topViewController as? AppIsWorkingViewController) == nil {
                        self.performSegue(withIdentifier: "showAppWorking", sender: self)
                    }
                } else {
                    self.performSegue(withIdentifier: "showMain", sender: self)
                }
            } else {
                if BluetraceManager.shared.isBluetoothAuthorized() {
                    self.performSegue(withIdentifier: "showTurnOnBluetooth", sender: nil)
                } else if FormRegisterPassportProfileController().tempPassportData != nil {
                    showPassportHoldingScreen()
                } else {
                    // if Bluetooth is not authorised, we will not be able to tell if it is turned on
                    self.performSegue(withIdentifier: "showMain", sender: self)
                }
            }
            nextButton.isEnabled = true
        }
    }

    func showPassportHoldingScreen() {
        let passportHoldingVC = UIStoryboard(name: "PassportHolding", bundle: nil).instantiateInitialViewController()!
        navigationController!.setViewControllers([passportHoldingVC], animated: true)
    }
}
