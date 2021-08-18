//
//  FormRegisterPassportProfileController.swift
//  OpenTraceTogether

import UIKit
import SafariServices

class FormRegisterPassportProfileController: FormRegisterProfileController {

    var infoCell: FormLabelCell!
    var nameCell: FormTextFieldCell!
    var dobCell: FormTextFieldCell!
    var passportCell: FormTextFieldCell!
    var nationalityCell: FormTextFieldCell!

    override var idType: String {
        return "passport"
    }

    override var screenName: String {
        return "OnBoardProfileVisit"
    }

    override var data: [String: Any?] {
        return tempPassportData ?? [:]
    }

    var tempPassportData: [String: String]? {
        get {
            var value = UserDefaults.standard.object(forKey: "TempPassportData") as? [String: String]
            value?["id"] = try? SecureStore.readCredentials(service: "passportService", accountName: "id").password
            return value
        }
        set {
            var value = newValue
            try? SecureStore.addOrUpdateCredentials(.init(username: "id", password: value?["id"] ?? ""), service: "passportService")
            value?.removeValue(forKey: "id")
            UserDefaults.standard.set(value, forKey: "TempPassportData")
        }
    }

    override func setupView() {
        super.setupView()
        headerCell.titleLabel.text = NSLocalizedString("PassportDetailsTitle", comment: "")
        infoCell = createInfoCell(title: "PassportDetailsInfo")

        nameCell = createTextFieldCell(icon: "person", title: "Name")

        dobCell = createTextFieldCell(icon: "calendar", title: "DateOfBirthForPassportUsers", placeholder: "dd-mmm-yyyy")
        dobCell.setAsListPicker(BirthDateListPickerDataSource())
        dobCell.serverErrorType = .lineOnly

        nationalityCell = createTextFieldCell(icon: "nationality", title: "Nationality")
        nationalityCell.setAsListPicker(CountryNameListPickerDataSource())
        nationalityCell.serverErrorType = .lineOnly

        passportCell = createTextFieldCell(icon: "passport", title: "passportNumber")
        passportCell.serverErrorType = .allow
        passportCell.valueChanged = { [weak self] in self?.checkPassportNumber() }

        cells = [[infoCell, nameCell, dobCell, nationalityCell, passportCell]]
        prefillFromTempData()
    }

    func prefillFromTempData() {
        if let tempData = tempPassportData {
            passportCell.setTextFieldText(tempData["id"])
            nameCell.setTextFieldText(tempData["name"])
            dobCell.setTextFieldText(displayDate(from: tempData["dateOfBirth"]))
            nationalityCell.setTextFieldText(displayNationality(from: tempData["nationality"]))
            footerCell.checkBoxButton.isSelected = true
            footerCell.submitButton.setTitle(NSLocalizedString("UPDATE", comment: "UPDATE"), for: .normal)
            checkReady()
        }
    }

    override func setupViewForStaticProfile() {
        super.setupViewForStaticProfile()
        cells[0].append(createLabelCell(icon: .nationality, title: .nationality, key: .nationality))
        cells[0].append(createLabelCell(icon: .passport, title: .passportNumber, key: .id))
    }

    func setupViewForPassportHoldingVC(_ vc: PassportHoldingViewController) {
        if let tempData = tempPassportData {
            vc.passportNumLabel.text = tempData["id"]
            vc.nameLabel.text = tempData["name"]
            vc.nationalityLabel.text = displayNationality(from: tempData["nationality"])
            vc.birthLabel.text = displayDate(from: tempData["dateOfBirth"])
        }
    }

    private func displayNationality(from serverNationality: String! = "") -> String {
        return Locale.countryName(from: serverNationality)!.uppercased()
    }

    private func serverNationality(from displayNationality: String! = "") -> String {
        return Locale.isoCode(from: displayNationality)!
    }

    override func submit(in sender: UIViewController, _ completion: ((FirebaseAPIs.UpdateUserInfoResultType) -> Void)? = nil) {
        tempPassportData = [
            "id": passportCell!.textField.text!,
            "name": nameCell!.textField.text!,
            "nationality": serverNationality(from: nationalityCell!.textField.text!),
            "dateOfBirth": serverDate(from: dobCell!.textField.text!)
        ]
        let nav = sender.navigationController!
        if nav.viewControllers.contains(where: { $0 is PassportHoldingViewController }) {
            nav.popViewController(animated: true)
        } else {
            let vc = UIStoryboard(name: "AllowPermission", bundle: nil).instantiateInitialViewController() as! AllowBlueToothNotificationViewController
            nav.setViewControllers([vc], animated: true)
        }
        completion?(.success)
    }

    func activateApp(in sender: UIViewController) {
        super.submit(in: sender) { resultType in
            switch resultType {
            case .validationFailed:
                let title = NSLocalizedString("PassportInvalidTitle", comment: "")
                let details = NSLocalizedString("PassportInvalidDetails", comment: "")
                let help = NSLocalizedString("Help", comment: "")
                let ok = NSLocalizedString("OK", comment: "")
                let alert = UIAlertController(title: title, message: details, preferredStyle: .alert)
                alert.addAction(.init(title: ok, style: .default, handler: nil))
                alert.addAction(.init(title: help, style: .cancel) { _ in
                    let helpVC = SFSafariViewController(url: URL(string: "https://support.tracetogether.gov.sg/hc/en-sg/articles/360056446054-I-can-t-activate-my-TraceTogether-App-What-should-I-do-")!)
                    sender.present(helpVC, animated: true, completion: nil)
                })
                sender.present(alert, animated: true, completion: nil)
            case .success, .successWithPermissionTurnedOn, .useDifferentProfile:
                self.tempPassportData = nil
            default:
                break
            }
        }
    }

    func checkPassportNumber() {
        passportCell.error = nil
        if let passportNumber = passportCell.textField.text, passportNumber.isEmpty == false, PassportChecker.validPassport(passportNumber) == false {
            passportCell.error = NSLocalizedString("InvalidPassportFormat", comment: "Invalid Passport format")
        }
        checkReady()
    }
}

private class CountryNameListPickerDataSource: ListPickerDataSource {
    var allData: [[String]] = [Locale.countryNames]

    var initialData: [String] {
        return [allData[0][0]]
    }

    func value(from data: [String]) -> String {
        return data[0]
    }

    func data(from value: String) -> [String] {
        return [value]
    }
}

private class BirthDateListPickerDataSource: ListPickerDataSource {

    var allData: [[String]] = {
        let days = ["-"] + (1...31).map { "\($0)" }
        let months = ["-"] + DateFormatter.appDateFormatter(format: "").monthSymbols!
        let currentYear = Calendar.appCalendar.component(.year, from: Date())
        let years = (1...150).map { "\(currentYear - 150 + $0)" }
        return [days, months, years]
    }()

    var initialData: [String] {
        return [allData[0][1], allData[1][1], allData[2][130]]
    }

    func value(from data: [String]) -> String {
        if data[1] == "-" {
            return data[2]
        }
        var date = DateFormatter.appDateFormatter(format: "MMMM-yyyy").date(from: "\(data[1])-\(data[2])")!
        var dateFormat = "MMM-yyyy"
        if data[0] != "-" {
            let maxDay = Calendar.appCalendar.range(of: .day, in: .month, for: date)!.count
            let day = min(Int(data[0])!, maxDay) - 1
            date = Calendar.appCalendar.date(byAdding: .day, value: day, to: date)!
            dateFormat = "dd-MMM-yyyy"
        }
        return DateFormatter.appDateFormatter(format: dateFormat).string(from: min(date, Date()))
    }

    func data(from value: String) -> [String] {
        let data = value.split(separator: "-")
        if data.count == 1, Int(value) != nil {
            return ["-", "-", value]
        } else if data.count == 2 {
            return ["-"] + DateFormatter.convert(value, from: "MMM-yyyy", to: "MMMM-yyyy").components(separatedBy: "-")
        } else if data.count == 3 {
            return DateFormatter.convert(value, from: "dd-MMM-yyyy", to: "d-MMMM-yyyy").components(separatedBy: "-")
        } else {
            return initialData
        }
    }
}
