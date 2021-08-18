//
//  AddFamilyMemberViewController.swift
//  OpenTraceTogether

import UIKit
import CoreData

class AddFamilyMemberViewController: UIViewController {

    @IBOutlet weak var nricFinTextField: UITextField!
    @IBOutlet weak var errorMessageLabel: UILabel!
    @IBOutlet weak var nricValidationTickImageView: UIImageView!
    @IBOutlet weak var nickNameView: UIView!
    @IBOutlet weak var nricFinView: UIView!
    @IBOutlet weak var addNickNameLabel: UILabel!
    @IBOutlet weak var nickNameTextField: UITextField!
    @IBOutlet weak var addBtn: UIButton!

    var familyMemberImageNameArray = ["redMerlion.png", "orangeOtter.png", "blueMerlion.png", "tealOtter.png"]
    var existingFamilyMembers: [FamilyMemberRef] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nricFinTextField.delegate = self
        nickNameTextField.delegate = self
        
        addBtn.setBackgroundColor(color: UIColor(hexString: "#F2F2F2"), forState: .normal)
        addBtn.setTitleColor(UIColor(hexString: "#BDBDBD"), for: .normal)
        
        nricFinTextField.addTarget(self, action: #selector(checkTextField), for: .editingChanged)
        nickNameTextField.addTarget(self, action: #selector(checkTextField), for: .editingChanged)
        
        dismissKeyboardOnTap()
        
        do {
            //Cache existing members to avoid fetching it at each key stroke
            existingFamilyMembers = try SecureStore.getAllFamilyMembers()
        } catch {
            LogMessage.create(type: .Error, title: #function, details: error.localizedDescription, collectable: true)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = true
        nricFinTextField.becomeFirstResponder()

    }

    @IBAction func backBtnPressed(_ sender: UIBarButtonItem) {
        self.navigationController?.popViewController(animated: true)
    }

    @objc func checkTextField(_ textField: UITextField) {
        if let nickname = nickNameTextField.text, let nric = nricFinTextField.text, nickname.isEmpty || nric.isEmpty || nric.count < 9 {
            addBtn.setBackgroundColor(color: UIColor(hexString: "#F2F2F2"), forState: .normal)
            addBtn.setTitleColor(UIColor(hexString: "#BDBDBD"), for: .normal)
            addBtn.isUserInteractionEnabled = false
        } else {
            addBtn.setBackgroundColor(color: UIColor(hexString: "#FF6565"), forState: .normal)
            addBtn.setTitleColor(UIColor(hexString: "#FFFFFF"), for: .normal)
            addBtn.isUserInteractionEnabled = true
        }
    }

    func checkNric(idString: String) {
        //User should not be allowed to add himself
        do {
            let userIdValue = try SecureStore.readCredentials(service: "nricService", accountName: "id").password
            if (idString.caseInsensitiveCompare(userIdValue) == .orderedSame) {
                errorMessageLabel.text = NSLocalizedString("UniqueNRIC", comment: "This NRIC/FIN has already been added.")
                return
            }
        } catch {
            if let error = error as? SecureStore.KeychainError {
                if #available(iOS 11.3, *) {
                    LogMessage.create(type: .Error, title: #function, details: "KeychainError: \(error.localizedDescription)")
                } else {
                    LogMessage.create(type: .Error, title: #function, details: "KeychainError: \(error)", debugMessage: "KeychainError: \(error)")
                }
            }
        }

        //User should be allowed to add any valid and non-duplicate NRIC or FIN
        let isValid = NricFinChecker.validNricFin(idString, profileType: .NRIC) ||
            NricFinChecker.validNricFin(idString, profileType: .FIN)

        switch isValid {
        case true:
            let nricExists = checkForUniqueNRIC(nricString: idString.uppercased())
            if nricExists {
                errorMessageLabel.text = NSLocalizedString("UniqueNRIC", comment: "This NRIC/FIN has already been added.")
                nricValidationTickImageView.isHidden = true
                nickNameView.isHidden = true
                addNickNameLabel.isHidden = true
            } else {
                nricValidationTickImageView.isHidden = false
                nickNameView.isHidden = false
                addNickNameLabel.isHidden = false
                nickNameTextField.text = ""
                nricFinView.layer.borderColor = UIColor.lightGray.cgColor
                nickNameView.layer.borderColor = UIColor.darkGray.cgColor
                errorMessageLabel.text = ""
            }
            break
        default:
            nricValidationTickImageView.isHidden = true
            nickNameView.isHidden = true
            addNickNameLabel.isHidden = true
            errorMessageLabel.text = NSLocalizedString("InvalidNRICFIN", comment: "Invalid NRIC/FIN. Enter a valid NRIC/FIN")
        }
    }

    @IBAction func addBtnPressed(_ sender: UIButton) {
        saveFamilyMember()
        self.navigationController?.popViewController(animated: true)
    }

    func saveFamilyMember() {
        var familyMember = FamilyMemberRef()
        familyMember.familyMemberName = nickNameTextField.text
        familyMember.familyMemberNRIC = nricFinTextField.text?.uppercased()
        familyMember.dateSortDescriptor = Date()
        var currentIndex = UserDefaults.standard.integer(forKey: "imageOrderNumber")
        familyMember.familyMemberImage = familyMemberImageNameArray[currentIndex]
        if currentIndex == familyMemberImageNameArray.count - 1 {
            currentIndex = 0
        } else {
            currentIndex += 1
        }
        UserDefaults.standard.set(currentIndex, forKey: "imageOrderNumber")
        do {
             try SecureStore.addFamilyMember(familyMember: familyMember)
             LogMessage.create(type: .Info, title: #function, details: "Saved new member successfully", collectable: true)
         } catch {
             LogMessage.create(type: .Error, title: #function, details: error.localizedDescription, collectable: true)
             print("Storing data Failed")
         }
    }

    func checkForUniqueNRIC(nricString: String) -> Bool {
        return existingFamilyMembers.contains { $0.familyMemberNRIC == nricString }
    }

    override func viewWillDisappear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = false
    }
}

extension AddFamilyMemberViewController: UITextFieldDelegate {

    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField.tag == 0 {
            let maxLength = 9
            nricValidationTickImageView.isHidden = true
            nickNameView.isHidden = true
            addNickNameLabel.isHidden = true
            let currentString: NSString = textField.text! as NSString
            let newString: NSString = currentString.replacingCharacters(in: range, with: string) as NSString

            //Don't show error message if nricFinTextField is empty
            if  newString == "" {
                errorMessageLabel.text = ""
            }

            if newString.length == maxLength {
                checkNric(idString: newString as String)
                return true
            }

            if newString.length > maxLength {
                let nickName = nickNameTextField.text
                checkNric(idString: String((newString as String).dropLast()))
                nickNameTextField.text = nickName
                return false
            }
            return newString.length <= maxLength
        } else {
            nricValidationTickImageView.isHidden = false
            nickNameView.isHidden = false
            addNickNameLabel.isHidden = false
            return true
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.tag == 0 {
            nricFinView.layer.borderColor = UIColor.darkGray.cgColor
        } else {
            nickNameView.layer.borderColor = UIColor.darkGray.cgColor
        }
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.tag == 0 {
            nricFinView.layer.borderColor = UIColor.lightGray.cgColor
        } else {
            nickNameView.layer.borderColor = UIColor.lightGray.cgColor
        }
    }
}
