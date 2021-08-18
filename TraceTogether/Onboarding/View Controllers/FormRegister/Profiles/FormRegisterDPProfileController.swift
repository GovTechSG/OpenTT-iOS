//
//  FormRegisterDPProfileController.swift
//  OpenTraceTogether

import UIKit

class FormRegisterDPProfileController: FormRegisterProfileController {

    var nameCell: FormTextFieldCell!
    var finCell: FormTextFieldCell!
    var serialCell: FormTextFieldCell!

    override var idType: String {
        return "finDP"
    }

    override var screenName: String {
        return "OnBoardProfileWPDP"
    }

    override var data: [String: Any?] {
        return [
            "id": finCell?.textField?.text,
            "name": nameCell?.textField?.text,
            "cardSerialNumber": serialCell?.textField?.text,
        ]
    }

    override func setupView() {
        super.setupView()
        headerCell.titleLabel.text = NSLocalizedString("FinDPDetailsTitle", comment: "")
        nameCell = createTextFieldCell(icon: "person", title: "Name")

        finCell = createTextFieldCell(icon: "card", title: "FINString", placeholder: "e.g. G1234567A")
        finCell.maxLength = 9
        finCell.serverErrorType = .allow
        finCell.valueChanged = { [weak self] in self?.checkFIN() }

        serialCell = createTextFieldCell(icon: "number", title: "cardSerialNumber")
        serialCell.serverErrorType = .lineOnly
        serialCell.onFind = { [weak self] in self?.performSegueId("DPModal") }

        cells = [[nameCell, finCell, serialCell]]
    }

    override func setupViewForStaticProfile() {
        super.setupViewForStaticProfile()
        cells[0].append(createLabelCell(icon: .card, title: .FIN, key: .id))
        cells[0].append(createLabelCell(icon: .number, title: .serialNumber, key: .serialNumber))
    }

    func checkFIN() {
        if finCell.textField.text!.count > 0 && (finCell.textField.text?.first == "S" || finCell.textField.text?.first == "T") {
            finCell.error = NSLocalizedString("TapBackAndSelectNRIC", comment: "Please tap back and select the Singaporean profile")
        } else if finCell.textField.text!.count > 0 && !NricFinChecker.validNricFin(finCell.textField.text!, profileType: .FINDependentPass) {
            finCell.error = NSLocalizedString("InvalidFin", comment: "Invalid FIN")
        } else {
            finCell.error = nil
        }
        checkReady()
    }
}
