//
//  FormRegisterWPProfileController.swift
//  OpenTraceTogether

import UIKit

class FormRegisterWPProfileController: FormRegisterProfileController {

    var ownCardCell: FormRadioCell!
    var nameCell: FormTextFieldCell!
    var finCell: FormTextFieldCell!
    var serialCell: FormTextFieldCell!
    var doaCell: FormTextFieldCell!
    var ownCard = true

    override var idType: String {
        return "finWP"
    }

    override var screenName: String {
        return "OnboardProfileWPDP"
    }

    override var data: [String: Any?] {
        return [
            "id": finCell?.textField?.text,
            "name": nameCell?.textField?.text,
            "idDateOfApplication": ownCard ? "" : serverDate(from: doaCell?.textField?.text),
            "cardSerialNumber": ownCard ? serialCell?.textField?.text : "",
        ]
    }

    override func setupView() {
        super.setupView()
        headerCell.titleLabel.text = NSLocalizedString("FinWPDetailsTitle", comment: "")
        ownCardCell = createRadioCell(title: "OwnFINCard", options: ["Yes", "No"])
        ownCardCell.valueChanged = { [weak self] in self?.checkOwnCard() }

        nameCell = createTextFieldCell(icon: "person", title: "Name")

        finCell = createTextFieldCell(icon: "card", title: "FINString", placeholder: "e.g. G1234567A")
        finCell.maxLength = 9
        finCell.serverErrorType = .allow
        finCell.valueChanged = { [weak self] in self?.checkFIN() }

        serialCell = createTextFieldCell(icon: "number", title: "cardSerialNumber")
        serialCell.serverErrorType = .lineOnly
        serialCell.onFind = { [weak self] in self?.performSegueId("WPSNModal") }

        doaCell = createTextFieldCell(icon: "calendar", title: "DateOfApplication", placeholder: "dd-mmm-yyyy")
        doaCell.setAsDatePicker()
        doaCell.serverErrorType = .lineOnly
        doaCell.onFind = { [weak self] in self?.performSegueId("WPDoAModal") }

        setEnabledForm(false)
        reloadCells()
    }

    override func setupViewForStaticProfile() {
        super.setupViewForStaticProfile()
        cells[0].append(createLabelCell(icon: .card, title: .FIN, key: .id))
        cells[0].append(createLabelCell(icon: .number, title: .serialNumber, key: .serialNumber))
    }

    func setEnabledForm(_ enabled: Bool) {
        [nameCell, finCell, serialCell, doaCell, footerCell].forEach { (cell) in
            cell!.contentView.alpha = enabled ? 1 : 0.3
            cell!.contentView.isUserInteractionEnabled = enabled
        }
    }

    func reloadCells() {
        cells = [[ownCardCell, nameCell, finCell], ownCard ? [serialCell] : [doaCell]]
    }

    func checkOwnCard() {
        setEnabledForm(true)

        let ownCard = ownCardCell.option1Button.isSelected
        if (self.ownCard != ownCard) {
            self.ownCard = ownCard
            reloadCells()
            tableView.reloadSections(IndexSet(integer: 2), with: .automatic)
        }
    }

    func checkFIN() {
        if finCell.textField.text!.count > 0 && (finCell.textField.text?.first == "S" || finCell.textField.text?.first == "T") {
            finCell.error = NSLocalizedString("TapBackAndSelectNRIC", comment: "Please tap back and select the Singaporean profile")
        } else if finCell.textField.text!.count > 0 && !NricFinChecker.validNricFin(finCell.textField.text!, profileType: .FINWorkPass) {
            finCell.error = NSLocalizedString("InvalidFin", comment: "Invalid FIN")
        } else {
            finCell.error = nil
        }
        checkReady()
    }
}
