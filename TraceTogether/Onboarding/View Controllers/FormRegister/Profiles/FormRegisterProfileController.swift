//
//  FormRegisterProfileProtocol.swift
//  OpenTraceTogether

import UIKit

protocol FormRegisterProfileControllerDelegate: class {
    func formRegisterProfileControllerWantsToPerformSegue(controller: FormRegisterProfileController, segueId: String)
    func formRegisterProfileControllerOnReady(controller: FormRegisterProfileController)
}

/// A parent class. Each profile need to extend from this class
class FormRegisterProfileController {

    enum SystemKey: String {
        case id = "id"
        case name = "name"
        case dateOfBirth = "dateOfBirth"
        case dateOfIssue = "idDateOfIssue"
        case dateOfApplication = "idDateOfApplication"
        case serialNumber = "cardSerialNumber"
        case mobileNumber = "mobilenumber"
        case nationality = "nationality"

        var storedValue: String? {
            get {
                switch (self) {
                case .id:
                    if let userIdValue = try? SecureStore.readCredentials(service: "nricService", accountName: "id").password {
                        return NricFinMask.maskUserId(userIdValue)
                    }
                    return nil
                case .mobileNumber:
                    return UserDefaults.standard.string(forKey: "numberWithCountryCode")
                case .nationality:
                    let countryCode = UserDefaults.standard.string(forKey: "userprofile_" + rawValue)
                    return Locale.countryName(from: countryCode)
                default:
                    return UserDefaults.standard.string(forKey: "userprofile_" + rawValue)
                }
            }
        }
    }

    enum Title: String {
        case name = "Name"
        case NRIC = "NricBirthCert"
        case FIN = "FINString"
        case dateOfBirth = "DateOfBirth"
        case dateOfIssue = "DateOfIssue"
        case dateOfApplication = "DateOfApplication"
        case serialNumber = "cardSerialNumber"
        case passportNumber = "passportNumber"
        case mobileNumber = "MobileNumber"
        case nationality = "Nationality"
    }

    enum Icon: String {
        case person = "person"
        case calendar = "usercalendar"
        case card = "card"
        case number = "number"
        case mobile = "mobile"
        case passport = "passport"
        case nationality = "nationality"
    }

    var tableView: UITableView!

    lazy var headerCell: FormLabelCell! = tableView?.dequeueReusableCell(withIdentifier: "HeaderCell") as? FormLabelCell
    lazy var footerCell: FormFooterCell! = tableView?.dequeueReusableCell(withIdentifier: "FooterCell") as? FormFooterCell

    var cells: [[UITableViewCell]] = [[]]

    var ready = false {
        didSet {
            delegate?.formRegisterProfileControllerOnReady(controller: self)
        }
    }

    weak var delegate: FormRegisterProfileControllerDelegate?

    required init() {}

    static func from(_ profile: ProfileType) -> FormRegisterProfileController {
        let profiles: [ProfileType: FormRegisterProfileController.Type] = [
            .NRIC: FormRegisterNRICProfileController.self,
            .FINWorkPass: FormRegisterWPProfileController.self,
            .FINDependentPass: FormRegisterDPProfileController.self,
            .FINStudentPass: FormRegisterSTPProfileController.self,
            .FINLongTermVisitorPass: FormRegisterLTVPProfileController.self,
            .Visitor: FormRegisterPassportProfileController.self,
        ]
        return profiles[profile]!.init()
    }

    var idType: String {
        return ""
    }

    var screenName: String {
        return ""
    }

    /// For registration params
    var data: [String: Any?] {
        return [:]
    }

    /// This if for formRegister page
    func setupView() {
        headerCell.backButton.accessibilityLabel = NSLocalizedString("Back", comment: "Back")
        footerCell.backButton.accessibilityLabel = NSLocalizedString("Back", comment: "Back")
    }

    /// This is for profile page
    func setupViewForStaticProfile() {
        cells[0].append(createLabelCell(icon: .person, title: .name, key: .name))
        cells[0].append(createLabelCell(icon: .mobile, title: .mobileNumber, key: .mobileNumber))
    }

    /// To handle whether register button enabled or not. By default it only check whether all textFieldCell has value & no error.
    func checkReady() {
        let textFieldCells = cells.reduce([], { $0 + $1 }).filter { $0 is FormTextFieldCell } as! [FormTextFieldCell]
        ready = textFieldCells.allSatisfy { $0.textField.text!.count > 0 && $0.error == nil }
    }

    func performSegueId(_ segueId: String) {
        delegate?.formRegisterProfileControllerWantsToPerformSegue(controller: self, segueId: segueId)
    }

    func createTextFieldCell(icon: String, title: String, placeholder: String = "") -> FormTextFieldCell {
        let cell = (tableView.dequeueReusableCell(withIdentifier: "TextFieldCell") as! FormTextFieldCell)
        cell.iconView.image = UIImage(named: icon)
        cell.titleLabel.text = NSLocalizedString(title, comment: "")
        cell.textField.placeholder = NSLocalizedString(placeholder, comment: "")
        cell.valueChanged = { [weak self] in self?.checkReady() }
        return cell
    }

    func createNoteCell(note: String) -> FormNoteCell {
        let cell = (tableView.dequeueReusableCell(withIdentifier: "NoteCell") as! FormNoteCell)
        cell.noteLabel.text = NSLocalizedString(note, comment: "")
        return cell
    }

    func createRadioCell(title: String, options: [String]) -> FormRadioCell {
        let cell = (tableView.dequeueReusableCell(withIdentifier: "RadioCell") as! FormRadioCell)
        cell.titleLabel.text = NSLocalizedString(title, comment: "")
        cell.valueChanged = { [weak self] in self?.checkReady() }
        cell.optionButtons.forEach { $0.isHidden = true }
        for (i, option) in options.enumerated() {
            cell.optionButtons[i].setTitle(NSLocalizedString(option, comment: ""), for: .normal)
            cell.optionButtons[i].accessibilityIdentifier = option
            cell.optionButtons[i].isHidden = false
        }
        return cell
    }

    func createLabelCell(icon: Icon, title: Title, key: SystemKey) -> FormLabelCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LabelCell") as! FormLabelCell
        cell.iconView.image = UIImage(named: icon.rawValue)
        cell.titleLabel.text = NSLocalizedString(title.rawValue, comment: "")
        cell.valueLabel.text = key.storedValue?.uppercased()
        return cell
    }

    func createInfoCell(icon: String = "ic-info", title: String) -> FormLabelCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "InfoCell") as! FormLabelCell
        cell.iconView.image = UIImage(named: icon)
        cell.titleLabel.text = NSLocalizedString(title, comment: "")
        return cell
    }

    func serverDate(from displayDate: String! = "") -> String {
        let data = displayDate.split(separator: "-")
        if data.count == 1, Int(displayDate) != nil {
            return DateFormatter.convert(displayDate, from: "yyyy", to: "00-00-yyyy")
        } else if data.count == 2 {
            return DateFormatter.convert(displayDate, from: "MMM-yyyy", to: "00-MM-yyyy")
        } else if data.count == 3 {
            return DateFormatter.convert(displayDate, from: "dd-MMM-yyyy", to: "dd-MM-yyyy")
        } else {
            return ""
        }
    }

    func displayDate(from serverDate: String! = "") -> String {
        if serverDate.starts(with: "00-00-") {
            return DateFormatter.convert(serverDate, from: "00-00-yyyy", to: "yyyy").uppercased()
        } else if serverDate.starts(with: "00-") {
            return DateFormatter.convert(serverDate, from: "00-MM-yyyy", to: "MMM-yyyy").uppercased()
        } else {
            return DateFormatter.convert(serverDate, from: "dd-MM-yyyy", to: "dd-MMM-yyyy").uppercased()
        }
    }

    func submit(in sender: UIViewController, _ completion: ((FirebaseAPIs.UpdateUserInfoResultType) -> Void)? = nil) {
        updateUserInfo(in: sender, completion)
    }

    private func updateUserInfo(in sender: UIViewController, _ completion: ((FirebaseAPIs.UpdateUserInfoResultType) -> Void)? = nil) {
        if !InternetConnectionManager.isConnectedToNetwork() {
            let alert = UIAlertController.noInternetAlertController { self.updateUserInfo(in: sender, completion) }
            return sender.present(alert, animated: true, completion: nil)
        }
        LoadingViewController.present(in: sender)
        FirebaseAPIs.updateUserInfo(formFieldsDict: data as [String: Any], idType: idType) { (resultType) in
            LoadingViewController.dismiss(in: sender) {
                switch resultType {
                case .needPermission:
                    let vc = UIStoryboard(name: "AllowPermission", bundle: nil).instantiateInitialViewController()!
                    sender.navigationController?.setViewControllers([vc], animated: true)
                case .successWithPermissionTurnedOn:
                    let vc = UIStoryboard(name: "AllowPermission", bundle: nil).instantiateViewController(withIdentifier: "AppIsWorkingViewController")
                    sender.navigationController?.setViewControllers([vc], animated: true)
                case .success:
                    let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "main")
                    sender.navigationController?.setViewControllers([vc], animated: true)
                case .validationFailed:
                    let msg = NSLocalizedString("NRICValidationFailed", comment: "Validation failed; check all fields in red")
                    self.cells.reduce([], { $0 + $1 }).forEach { ($0 as? FormTextFieldCell)?.serverError = msg }
                case .shouldStartOver:
                    OnboardingManager.shared.showAlertAndStartOver(sender)
                case .commonError:
                    sender.present(UIAlertController.temporarilyUnavailableAlertController(), animated: true, completion: nil)
                case .useDifferentProfile:
                    let title = NSLocalizedString("RegisterWithFINTitle", comment: "")
                    let message = NSLocalizedString("RegisterWithFINMessage", comment: "")
                    let ok = NSLocalizedString("Ok", comment: "")
                    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                    alert.addAction(.init(title: ok, style: .cancel) { _ in
                        let vc = UIStoryboard(name: "ProfileSelection", bundle: nil).instantiateInitialViewController()!
                        sender.navigationController?.setViewControllers([vc], animated: true)
                    })
                    sender.present(alert, animated: true, completion: nil)
                case .rateLimitError:
                    let title = NSLocalizedString("PleaseTryAgainLater", comment: "Please try again later.")
                    let message = NSLocalizedString("TooManyTries", comment: "There were too many error tries.")
                    let ok = NSLocalizedString("Ok", comment: "")
                    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                    alert.addAction(.init(title: ok, style: .default, handler: nil))
                    sender.present(alert, animated: true, completion: nil)
                }
                completion?(resultType)
            }
        }
    }
}
