//
//  FormRegisterLTVPProfileController.swift
//  OpenTraceTogether

import UIKit

class FormRegisterLTVPProfileController: FormRegisterProfileController {

    var nameCell: FormTextFieldCell!
    var finCell: FormTextFieldCell!
    var serialCell: FormTextFieldCell!
    var doiCell: FormTextFieldCell!

    override var idType: String {
        return "finLTVP"
    }

    override var screenName: String {
        return "OnBoardProfileSTPLTVP"
    }

    override var data: [String: Any?] {
        return [
            "id": finCell?.textField?.text,
            "name": nameCell?.textField?.text,
            "cardSerialNumber": serialCell?.textField?.text,
            "idDateOfIssue": serverDate(from: doiCell?.textField?.text),
        ]
    }

    override func setupView() {
        super.setupView()
        headerCell.titleLabel.text = NSLocalizedString("FinLTVPDetailsTitle", comment: "")
        nameCell = createTextFieldCell(icon: "person", title: "Name")

        finCell = createTextFieldCell(icon: "card", title: "FINString", placeholder: "e.g. G1234567A")
        finCell.maxLength = 9
        finCell.serverErrorType = .allow
        finCell.valueChanged = { [weak self] in self?.checkFIN() }

        serialCell = createTextFieldCell(icon: "number", title: "cardSerialNumber")
        serialCell.serverErrorType = .lineOnly
        serialCell.onFind = { [weak self] in self?.performSegueId("LTVPSNModal") }

        doiCell = createTextFieldCell(icon: "calendar", title: "FIN " + NSLocalizedString("DateOfIssue", comment: ""), placeholder: "dd-mmm-yyyy")
        doiCell.setAsDatePicker()
        doiCell.serverErrorType = .lineOnly
        doiCell.onFind = { [weak self] in self?.performSegueId("LTVPDoIModal") }

        cells = [[nameCell, finCell, serialCell, doiCell]]
    }

    override func setupViewForStaticProfile() {
        super.setupViewForStaticProfile()
        cells[0].append(createLabelCell(icon: .card, title: .FIN, key: .id))
        cells[0].append(createLabelCell(icon: .number, title: .serialNumber, key: .serialNumber))
    }

    func checkFIN() {
        if finCell.textField.text!.count > 0 && (finCell.textField.text?.first == "S" || finCell.textField.text?.first == "T") {
            finCell.error = NSLocalizedString("TapBackAndSelectNRIC", comment: "Please tap back and select the Singaporean profile")
        } else if finCell.textField.text!.count > 0 && !NricFinChecker.validNricFin(finCell.textField.text!, profileType: .FINLongTermVisitorPass) {
            finCell.error = NSLocalizedString("InvalidFin", comment: "Invalid FIN")
        } else {
            finCell.error = nil
        }
    }
}
