//
//  FormRegisterSTPProfileController.swift
//  OpenTraceTogether

import UIKit

class FormRegisterSTPProfileController: FormRegisterProfileController {

    var nameCell: FormTextFieldCell!
    var finCell: FormTextFieldCell!
    var doiCell: FormTextFieldCell!

    override var idType: String {
        return "finSTP"
    }

    override var screenName: String {
        return "OnBoardProfileSTPLTVP"
    }

    override var data: [String: Any?] {
        return [
            "id": finCell?.textField?.text,
            "name": nameCell?.textField?.text,
            "idDateOfIssue": serverDate(from: doiCell?.textField?.text),
        ]
    }

    override func setupView() {
        super.setupView()
        headerCell.titleLabel.text = NSLocalizedString("FinSTPDetailsTitle", comment: "")
        nameCell = createTextFieldCell(icon: "person", title: "Name")

        finCell = createTextFieldCell(icon: "card", title: "FINString", placeholder: "e.g. G1234567A")
        finCell.maxLength = 9
        finCell.serverErrorType = .allow
        finCell.valueChanged = { [weak self] in self?.checkFIN() }

        doiCell = createTextFieldCell(icon: "calendar", title: "FIN " + NSLocalizedString("DateOfIssue", comment: ""), placeholder: "dd-mmm-yyyy")
        doiCell.setAsDatePicker()
        doiCell.serverErrorType = .lineOnly
        doiCell.onFind = { [weak self] in self?.performSegueId("STPModal") }

        cells = [[nameCell, finCell, doiCell]]
    }

    override func setupViewForStaticProfile() {
        super.setupViewForStaticProfile()
        cells[0].append(createLabelCell(icon: .card, title: .FIN, key: .id))
    }

    func checkFIN() {
        if finCell.textField.text!.count > 0 && (finCell.textField.text?.first == "S" || finCell.textField.text?.first == "T") {
            finCell.error = NSLocalizedString("TapBackAndSelectNRIC", comment: "Please tap back and select the Singaporean profile")
        } else if finCell.textField.text!.count > 0 && !NricFinChecker.validNricFin(finCell.textField.text!, profileType: .FINStudentPass) {
            finCell.error = NSLocalizedString("InvalidFin", comment: "Invalid FIN")
        } else {
            finCell.error = nil
        }
        checkReady()
    }
}
