//
//  PhoneNumberViewController.swift

//  OpenTraceTogether

import UIKit
import FirebaseAuth
import CountryPickerView

class PhoneNumberViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var detailsLabel: UILabel!
    @IBOutlet weak var getOTPButton: UIButton!
    @IBOutlet weak var countryPickerParentView: UIView!
    let SG_PHONE_NUMBER_LENGTH = 8
    let POSTAL_CODE_LENGTH = 6
    let NRIC_FIN_LENGTH = 9
    let MIN_PHONE_NUMBER_LENGTH = 4

    var nricFinValid = false
    var postalCodeValid = false
    var phoneNumberValid = false
    var nricFinString: String?
    var postalCodeString: String?
    var fullNameString: String?
    var DOBString: String?
    var DOIString: String?
    var wrongNumberCheck: Bool?

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var countryPicker: CountryPickerView!

    // Textfields
    @IBOutlet weak var phoneNumberField: UITextField!
    @IBOutlet weak var noteLabel: UILabel!

    override func viewDidLoad() {

        super.viewDidLoad()
        let detailsLabelLocalizedText = NSLocalizedString("ContactYou", comment: "MOH will use this number to contact you if you had possible exposure to COVID-19.")
        detailsLabel.text = detailsLabelLocalizedText

        detailsLabel.accessibilityLabel =  detailsLabelLocalizedText.replacingOccurrences(of: "MOH", with: "M O H")

        phoneNumberField.becomeFirstResponder()
        phoneNumberField.accessibilityLabel = NSLocalizedString("EnterPhoneNumber", comment: "Enter your mobile number here")

        if #available(iOS 13.0, *) {
            activityIndicator.style = .large
        } else {
            activityIndicator.style = .whiteLarge
        }

        countryPickerParentView.layer.cornerRadius = 4
        countryPickerParentView.layer.borderColor = UIColor(hexString: "E0E0E0").cgColor
        countryPickerParentView.layer.borderWidth = 1

        countryPickerParentView.clipsToBounds = true

        self.phoneNumberField.addTarget(self, action: #selector(self.phoneNumberFieldDidChange), for: UIControl.Event.editingChanged)
        phoneNumberField.delegate = self

        countryPicker.font = UIFont.systemFont(ofSize: countryPicker.font.pointSize, weight: .regular)
        countryPicker.textColor = UIColor(hexString: "#333333")
        countryPicker.setCountryByName("Singapore")
        countryPicker.showCountryCodeInView = false
        countryPicker.hostViewController = self
        dismissKeyboardOnTap()

        countryPicker.countryDetailsLabel.addObserver(self, forKeyPath: "text", options: [.new], context: nil)
        handleCountryCodeChange(code: countryPicker.selectedCountry.phoneCode)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard let newCode = change?[.newKey] as? String else { return }

        handleCountryCodeChange(code: newCode)
    }

    func handleCountryCodeChange(code: String) {
        countryPicker.countryDetailsLabel.accessibilityLabel = String(format: NSLocalizedString("TapToChangeCountryCode", comment: "Selected Country code is %@. Tap to change country code"), code)
        code == "+65" ? (noteLabel.isHidden = true) : (noteLabel.isHidden = false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let tapFromWrongNumber = wrongNumberCheck {
            if tapFromWrongNumber {
                self.phoneNumberField.becomeFirstResponder()
            } else {
                dismissKeyboard()
            }
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AnalyticManager.setScreenName(screenName: "OnboardMobileNumber", screenClass: "PhoneNumberViewController")
    }

    @IBAction func backBtnClicked(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }

    @IBAction func getOTPButtonClicked(_ sender: Any) {
        getOTPButton.isEnabled = false
        self.getOTPButton.alpha = 0.5
        verifyPhoneNumberAndProceed(self.phoneNumberField.text!)
    }

    @objc
    func phoneNumberFieldDidChange() {
        phoneNumberField.layer.borderColor = UIColor(hexString: "a4a4a4").cgColor
        phoneNumberField.layer.borderWidth = 2.0
        phoneNumberField.layer.cornerRadius = 4.0

        if self.phoneNumberField.text?.count == SG_PHONE_NUMBER_LENGTH && countryPicker.selectedCountry.phoneCode == "+65" {
            self.phoneNumberField.resignFirstResponder()
        }
    }

    func verifyPhoneNumberAndProceed(_ number: String) {
        let numberWithCountryCode = countryPicker.selectedCountry.phoneCode + number
        UserDefaults.standard.set(countryPicker.selectedCountry.phoneCode, forKey: "countryCode")
        activityIndicator.startAnimating()
        FirebaseAPIs.verify(phoneNumber: numberWithCountryCode) { [weak self] (verificationID, error) in
            if let error = error {
                LogMessage.create(type: .Error, title: #function, details: "Verify phone API error: \(error.localizedDescription)")
                let errorAlert = UIAlertController(title: "Error verifying phone number", message: error.localizedDescription, preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
                    NSLog("Unable to verify phone number")
                    self?.activityIndicator.stopAnimating()
                }))
                self?.present(errorAlert, animated: true)
                LogMessage.create(type: .Error, title: #function, details: "Phone number verification error: \(error.localizedDescription)", debugMessage: "Phone number verification error: \(error.localizedDescription)")
                return
            }
            UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
            UserDefaults.standard.set(numberWithCountryCode, forKey: "numberWithCountryCode")
            self?.activityIndicator.stopAnimating()
            self?.performSegue(withIdentifier: "segueFromNumberToOTP", sender: self)
        }
    }

    //  limit text field input to 8 characters for SG
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var maxLength = 14 // World's longest is 14 digits in Brazil, 13 in India, 11 in China
        if textField == phoneNumberField && countryPicker.selectedCountry.phoneCode == "+65" {
            maxLength = SG_PHONE_NUMBER_LENGTH
        }
        let currentString: NSString = textField.text! as NSString
        let newString: NSString =
            currentString.replacingCharacters(in: range, with: string) as NSString
        textField.accessibilityLabel = newString == "" ? NSLocalizedString("EnterPhoneNumber", comment: "Enter your mobile number here") : ""
        return newString.length <= maxLength
    }

    // check again when all textfield ends editing
    func textFieldDidEndEditing(_ textField: UITextField) {
        let phoneNumberFieldTextUnwrapped = phoneNumberField.text ?? ""
        phoneNumberValid = phoneNumberFieldTextUnwrapped.count >= MIN_PHONE_NUMBER_LENGTH

        if phoneNumberValid {
            self.getOTPButton.isEnabled = true
            self.getOTPButton.alpha = 1
        } else {
            self.getOTPButton.isEnabled = false
            self.getOTPButton.alpha = 0.5
        }

        phoneNumberField.layer.cornerRadius = 4
        phoneNumberField.layer.borderColor = UIColor(hexString: "E0E0E0").cgColor
        phoneNumberField.layer.borderWidth = 1
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        phoneNumberField.layer.borderColor = UIColor(hexString: "a4a4a4").cgColor
        phoneNumberField.layer.borderWidth = 2.0
        phoneNumberField.layer.cornerRadius = 4.0
    }
}
