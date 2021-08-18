//
//  OTPViewController.swift
//  OpenTraceTogether

import UIKit
import FirebaseAuth
import FirebaseFunctions

class OTPViewController: UIViewController {

    enum Status {
        case InvalidOTP
        case WrongOTP
        case Success
    }

    // MARK: - UI

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var codeInputView: CodeInputView?
    @IBOutlet weak var errorMessageLabel: UILabel?

    @IBOutlet weak var wrongNumberButton: UIButton?
    @IBOutlet weak var resendCodeButton: UIButton?

    @IBOutlet weak var verifyButton: UIButton?

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    @IBOutlet weak var noteLabel: UILabel!

    var timer: Timer?

    var nricValue: String?
    var postalCode: String?
    var fullName: String?
    var DOB: String?
    var DOI: String?

    static let oneMin = 60
    static let userDefaultsPinKey = "XX"

    var countdownSeconds = oneMin
    lazy var functions = Functions.functions(region: "XX ")

    let linkButtonAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 16, weight: .medium), .foregroundColor: UIColor(red: 47/255, green: 128/255, blue: 237/255, alpha: 1.0), .underlineStyle: NSUnderlineStyle.single.rawValue]

    lazy var countdownFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        return formatter
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            activityIndicator.style = .large
        } else {
            activityIndicator.style = .whiteLarge
        }

        let wrongNumberButtonTitle = NSMutableAttributedString(string: NSLocalizedString("WrongNumber", comment: "Wrong number?"), attributes: linkButtonAttributes)
        wrongNumberButton?.setAttributedTitle(wrongNumberButtonTitle, for: .normal)
        resendCodeButton?.isEnabled = false

        dismissKeyboardOnTap()

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let numberWithCountryCode = UserDefaults.standard.string(forKey: "numberWithCountryCode") else {
            return
        }
        if UserDefaults.standard.string(forKey: "countryCode") == "+65" {
            var phoneNumber = numberWithCountryCode.replacingOccurrences(of: "+65", with: "")
            let halfLength = phoneNumber.count / 2
            let index = phoneNumber.index(phoneNumber.startIndex, offsetBy: halfLength)
            phoneNumber.insert(" ", at: index)
            let numberToDisplay = "+65" + " " + phoneNumber
            self.titleLabel.text = String(format: NSLocalizedString("EnterOTPSent", comment: "Enter OTP that was sent to %@."), numberToDisplay)
            noteLabel.isHidden = true
        } else {
            self.titleLabel.text = String(format: NSLocalizedString("EnterOTPSent", comment: "Enter OTP that was sent to %@."), numberWithCountryCode)
            noteLabel.isHidden = false
        }

        startTimer()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        _ = codeInputView?.becomeFirstResponder()
         AnalyticManager.setScreenName(screenName: "OnboardOTP", screenClass: "OTPViewController")
    }

    func startTimer() {
        countdownSeconds = OTPViewController.oneMin
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(OTPViewController.updateTimerCountdown), userInfo: nil, repeats: true)
        errorMessageLabel?.isHidden = true
        verifyButton?.isEnabled = true
        verifyButton?.alpha = 1.0
    }

    @objc
    func updateTimerCountdown() {
        countdownSeconds -= 1

        if countdownSeconds > 0 {
            let countdown = countdownFormatter.string(from: TimeInterval(countdownSeconds))!
            UIView.performWithoutAnimation {
                resendCodeButton?.setTitle(String(format: NSLocalizedString("ResendCountdown", comment: "Resend %@ s"), countdown), for: .disabled)
                resendCodeButton?.layoutIfNeeded()
            }
        } else {
            timer?.invalidate()
            resendCodeButton?.isEnabled = true
            resendCodeButton?.titleLabel?.text = NSLocalizedString("ResendOTP", comment: "Resend OTP")
            verifyButton?.isEnabled = false
            verifyButton?.alpha = 0.5
        }
    }

    @IBAction func resendCode(_ sender: UIButton) {
        guard let numberWithCountryCode = UserDefaults.standard.string(forKey: "numberWithCountryCode") else {
            performSegue(withIdentifier: "showEnterMobileNumber", sender: self)
            return
        }

        FirebaseAPIs.verify(phoneNumber: numberWithCountryCode) { [weak self] (verificationID, error) in
            if let error = error {
                let errorAlert = UIAlertController(title: "Error verifying phone number", message: error.localizedDescription, preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
                    NSLog("Unable to verify phone number")
                }))
                self?.present(errorAlert, animated: true)
                LogMessage.create(type: .Error, title: #function, details: "Phone number verification error: \(error.localizedDescription)", debugMessage: "Phone number verification error: \(error.localizedDescription)")
                return
            }
            UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
            UserDefaults.standard.set(numberWithCountryCode, forKey: "numberWithCountryCode")
        }

        startTimer()
    }

    func verifyOTP(_ result: @escaping (Status) -> Void) {
        activityIndicator.startAnimating()
        verifyButton?.isEnabled = false
        verifyButton?.alpha = 0.5
        guard let OTP = codeInputView?.text else {
            result(.InvalidOTP)
            return
        }

        guard OTP.range(of: "^[0-9]{6}$", options: .regularExpression) != nil else {
            result(.InvalidOTP)
            return
        }

        let verificationID = UserDefaults.standard.string(forKey: "authVerificationID") ?? ""
        FirebaseAPIs.signIn(withVerificationID: verificationID, otp: OTP) { (error) in
            if let error = error {
                // User was not signed in. Display error.
                LogMessage.create(type: .Error, title: #function, details: "FirebaseAPIs.signIn error \(error.localizedDescription)", debugMessage: "\(error.localizedDescription)")
                result(.WrongOTP)
                return
            }
            // User is signed in

            FirebaseAPIs.getHandshakePin { (pin) in
                if let pin = pin {
                    self.activityIndicator.stopAnimating()
                    UserDefaults.standard.set(pin, forKey: OTPViewController.userDefaultsPinKey)
                    result(.Success)
                } else {
                    result(.WrongOTP)
                    return
                }
            }
        }
    }

    @IBAction func verify(_ sender: UIButton) {
        verifyOTP { [unowned viewController = self] status in
            switch status {
            case .InvalidOTP:
                viewController.errorMessageLabel?.text = NSLocalizedString("InvalidOTP", comment: "Must be a 6-digit code")
                self.errorMessageLabel?.isHidden = false
                self.activityIndicator.stopAnimating()
                self.verifyButton?.isEnabled = true
                self.verifyButton?.alpha = 1
            case .WrongOTP:
                viewController.errorMessageLabel?.text = NSLocalizedString("WrongOTP", comment: "Wrong OTP entered")
                self.errorMessageLabel?.isHidden = false
                self.activityIndicator.stopAnimating()
                self.verifyButton?.isEnabled = true
                self.verifyButton?.alpha = 1
            case .Success:
                viewController.performSegue(withIdentifier: "showProfileSelection", sender: self)
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showEnterMobileNumber" {
            if let destinationVC = segue.destination as? PhoneNumberViewController {
                destinationVC.nricFinString = self.nricValue
                destinationVC.postalCodeString = self.postalCode
                destinationVC.DOBString = self.DOB
                destinationVC.DOIString = self.DOI
                destinationVC.fullNameString = self.fullName
                destinationVC.wrongNumberCheck = true
            }
        }
    }

}
