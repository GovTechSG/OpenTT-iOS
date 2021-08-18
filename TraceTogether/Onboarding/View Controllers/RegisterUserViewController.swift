//
//  RegisterUserViewController.swift
//  OpenTraceTogether

import UIKit
import FirebaseAuth
import CountryPickerView
import FirebaseAnalytics

class RegisterUserViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var registerButton: UIButton!
    let SG_PHONE_NUMBER_LENGTH = 8
    let POSTAL_CODE_LENGTH = 6
    let NRIC_FIN_LENGTH = 9
    let MIN_PHONE_NUMBER_LENGTH = 4

    var nricFinValid = false
    var postalCodeValid = false
    var nricFinString: String?
    var postalCodeString: String?
    var fullNameString: String?
    var DOBString: String?
    var DOIString: String?
    var wrongNumberCheck: Bool?
    // Error Labels
    @IBOutlet weak var nricFinErrLabel: UILabel!
    @IBOutlet weak var postcodeErrLabel: UILabel!
    @IBOutlet weak var fullNameErrLabel: UILabel!
    @IBOutlet weak var dobErrLabel: UILabel!
    @IBOutlet weak var doiErrLabel: UILabel!

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var howToFindView: UIView!

    // Textfields
    @IBOutlet weak var postalCodeField: UITextField!
    @IBOutlet weak var nricFinField: UITextField!
    @IBOutlet weak var fullNameField: UITextField!
    @IBOutlet weak var dobField: UITextField!
    @IBOutlet weak var doiField: UITextField!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var indicatorImage: UIImageView!

    override func viewDidLoad() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)

        super.viewDidLoad()
        #if RELEASE
        Analytics.setScreenName("OnboardRegistrationAfterOTP", screenClass: "RegisterUserViewController")
        #endif

        dobField.setInputViewDatePickerDOB(target: self, onChange: #selector(onDOBChange(_:)), onDone: #selector(tapDOBDone))
        doiField.setInputViewDatePicker(target: self, onChange: #selector(onDOIChange(_:)), onDone: #selector(tapDOIDone))
        dobField.tintColor = .clear

        if #available(iOS 13.0, *) {
            activityIndicator.style = .large
        } else {
            activityIndicator.style = .whiteLarge
        }

        self.postalCodeField.addTarget(self, action: #selector(self.postCodeFieldDidChange), for: UIControl.Event.editingChanged)
        self.nricFinField.addTarget(self, action: #selector(self.nricFinFieldDidChange), for: UIControl.Event.editingChanged)

        nricFinField.delegate = self
        postalCodeField.delegate = self
        fullNameField.delegate = self
        dobField.delegate = self
        doiField.delegate = self

        self.fullNameField.becomeFirstResponder()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    @objc func tapDOBDone() {
        if let datePicker = self.dobField.inputView as? UIDatePicker {
            let dateformatter = DateFormatter()
            dateformatter.dateFormat = "dd-MM-yyyy"
            self.dobField.text = dateformatter.string(from: datePicker.date)
        }
        self.dobField.resignFirstResponder()
        self.nricFinField.becomeFirstResponder()
    }

    @objc func onDOBChange(_ picker: UIDatePicker) {
        let dateformatter = DateFormatter()
        dateformatter.dateFormat = "dd-MM-yyyy"
        self.dobField.text = dateformatter.string(from: picker.date)
    }

    @objc func tapDOIDone() {
        if let datePicker = self.doiField.inputView as? UIDatePicker {
            let dateformatter = DateFormatter()
            dateformatter.dateFormat = "dd-MM-yyyy"
            self.doiField.text = dateformatter.string(from: datePicker.date)
        }
        self.doiField.resignFirstResponder()
        self.postalCodeField.becomeFirstResponder()
    }

    @objc func onDOIChange(_ picker: UIDatePicker) {
        let dateformatter = DateFormatter()
        dateformatter.dateFormat = "dd-MM-yyyy"
        self.doiField.text = dateformatter.string(from: picker.date)
    }

    @IBAction func registerButtonClicked(_ sender: Any) {
        activityIndicator.startAnimating()
        registerButton.isEnabled = false
        self.registerButton.alpha = 0.5
        self.view.isUserInteractionEnabled = false
        // if valid fire Firebase API
//        FirebaseAPIs.updateUserInfo(postalCode: self.postalCodeField.text, nricId: self.nricFinField.text, nricDOI: self.doiField.text, dob: self.dobField.text ) { (stId, error) in
//            self.activityIndicator.stopAnimating()
//            if let stIdValid = stId {
//                print("Valid stId \(stIdValid)")
//                UserDefaults.standard.set(stIdValid, forKey: "stId")
//                OnboardingManager.shared.hasRegistered = true
//                // If success
//                self.view.isUserInteractionEnabled = true
//                self.performSegue(withIdentifier: "showConsentFromRegisterUserSegue", sender: self)
//            } else {
//                print("Invalid stId received")
//                if error != nil {
//                    self.nricFinErrLabel.text = NSLocalizedString("NRICValidationFailed", comment: "Validation failed, check all fields in red")
//                    self.nricFinErrLabel.isHidden = false
//                    self.dobField.setRedBorder()
//                    self.doiField.setRedBorder()
//                    self.nricFinField.setRedBorder()
//                    self.registerButton.isEnabled = true
//                    self.registerButton.alpha = 1
//                    self.view.isUserInteractionEnabled = true
//                }
//            }
        //        }
        //        Comment the below away after API is ready
        self.view.isUserInteractionEnabled = true

        self.performSegue(withIdentifier: "showConsentFromRegisterUserSegue", sender: self)
    }

    @objc
    func postCodeFieldDidChange() {
        self.postalCodeValid = self.postalCodeField.text?.count == POSTAL_CODE_LENGTH
        if self.postalCodeField.text?.count == POSTAL_CODE_LENGTH {
            self.postalCodeField.resignFirstResponder()
        }
    }

    @objc
    func nricFinFieldDidChange() {
        self.nricFinField.text = self.nricFinField.text?.uppercased()
        if self.nricFinField.text?.count == NRIC_FIN_LENGTH {
            self.nricFinValid = NricFinChecker.validNricFin(self.nricFinField.text!)
            if self.nricFinValid {
                self.nricFinErrLabel.isHidden = true
                self.doiField.becomeFirstResponder()
            } else {
                self.nricFinErrLabel.isHidden = false
            }
        }
    }

    //    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    //        if segue.identifier == "segueFromNumberToOTP" {
    //            if let destinationVC = segue.destination as? OTPViewController {
    //                destinationVC.nricValue = self.nricFinField.text
    //                destinationVC.postalCode = self.postalCodeField.text
    //                destinationVC.fullName = self.fullNameField.text
    //                destinationVC.DOB = self.dobField.text
    //                destinationVC.DOI = self.doiField.text
    //            }
    //        }
    //    }

    //  limit text field input to 8 characters
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var maxLength = 14 // World's longest is 14 digits in Brazil, 13 in India, 11 in China
        if textField == nricFinField {
            maxLength = NRIC_FIN_LENGTH
        } else if textField == dobField {
            return false
        }
        let currentString: NSString = textField.text! as NSString
        let newString: NSString =
            currentString.replacingCharacters(in: range, with: string) as NSString
        return newString.length <= maxLength
    }

    // check again when all textfield ends editing
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.setNormalBorder()
        nricFinValid = NricFinChecker.validNricFin(nricFinField.text!)
        postalCodeValid = postalCodeField.text?.count == POSTAL_CODE_LENGTH

        switch textField {
        case fullNameField:
          runErrLabelLogic(logic: fullNameField.text?.count == 0, field: fullNameField, label: fullNameErrLabel)
        case postalCodeField:
          runErrLabelLogic(logic: !postalCodeValid, field: postalCodeField, label: postcodeErrLabel)
          runErrLabelLogic(logic: !nricFinValid, field: nricFinField, label: nricFinErrLabel)
          runErrLabelLogic(logic: doiField.text?.count == 0, field: doiField, label: doiErrLabel)
          runErrLabelLogic(logic: dobField.text?.count == 0, field: dobField, label: dobErrLabel)
          runErrLabelLogic(logic: fullNameField.text?.count == 0, field: fullNameField, label: fullNameErrLabel)
        case nricFinField:
          runErrLabelLogic(logic: !nricFinValid, field: nricFinField, label: nricFinErrLabel)
        case doiField:
            runErrLabelLogic(logic: doiField.text?.count == 0, field: doiField, label: doiErrLabel)
        case dobField:
            runErrLabelLogic(logic: dobField.text?.count == 0, field: dobField, label: dobErrLabel)
        default:
            print("nothing here")
        }
        //        if textField == phoneNumberField {
        //            let scrollFrame = CGRect(x: indicatorImage.frame.origin.x, y: indicatorImage.frame.origin.y + 8, width: indicatorImage.frame.size.width, height: indicatorImage.frame.size.height)
        //            scrollView.scrollRectToVisible(scrollFrame, animated: true)
        //        }

        if postalCodeValid && nricFinValid && doiField.text!.count > 0 && dobField.text!.count > 0 && fullNameField.text!.count > 0 {
            self.registerButton.isEnabled = true
            self.registerButton.alpha = 1
        } else {
            self.registerButton.isEnabled = false
            self.registerButton.alpha = 0.5
        }
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        switch textField {
        case nricFinField:
            nricFinErrLabel.isHidden = true
        case postalCodeField:
            postcodeErrLabel.isHidden = true
        case doiField:
            doiErrLabel.isHidden = true
        case dobField:
            dobErrLabel.isHidden = true
        case fullNameField:
            fullNameErrLabel.isHidden = true
        default:
            print("unknown field")
        }

        textField.setRedBorder()

    }

    func runErrLabelLogic(logic: Bool, field: UITextField, label: UILabel) {
        if logic {
            field.setRedBorder()
            label.isHidden = false
        } else {
            field.setNormalBorder()
            label.isHidden = true
        }
    }

    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                if postalCodeField.isFirstResponder {
                    self.view.frame.origin.y -= keyboardSize.height
                }
            }
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
}
