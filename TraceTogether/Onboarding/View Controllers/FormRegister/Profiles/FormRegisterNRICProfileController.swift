//
//  FormRegisterNRICProfileController.swift
//  OpenTraceTogether

import UIKit

class FormRegisterNRICProfileController: FormRegisterProfileController {

    var nameCell: FormTextFieldCell!
    var dobCell: FormTextFieldCell!
    var nricCell: FormTextFieldCell!
    var nricDoICell: FormTextFieldCell!
    var noteMinorCell: FormNoteCell!
    var noteNSCell: FormNoteCell!
    var isMinor = false

    override var idType: String {
        return "nric"
    }

    override var screenName: String {
        return "OnboardProfileNRIC"
    }

    override var data: [String: Any?] {
        return [
            "id": nricCell?.textField?.text,
            "name": nameCell?.textField?.text,
            "dateOfBirth": serverDate(from: dobCell?.textField?.text),
            "idDateOfIssue": isMinor ? "" :  serverDate(from: nricDoICell?.textField?.text)
        ]
    }

    override func setupView() {
        super.setupView()
        headerCell.titleLabel.text = NSLocalizedString("NRICDetailsTitle", comment: "")

        nameCell = createTextFieldCell(icon: "person", title: "Name")

        dobCell = createTextFieldCell(icon: "usercalendar", title: "DateOfBirth", placeholder: "dd-mmm-yyyy")
        dobCell.setAsDatePicker()
        dobCell.valueChanged = { [weak self] in self?.checkDoB() }

        nricCell = createTextFieldCell(icon: "card", title: "NricBirthCert", placeholder: "e.g. S1234567A")
        nricCell.maxLength = 9
        nricCell.serverErrorType = .allow
        nricCell.valueChanged = { [weak self] in self?.checkNRIC() }

        nricDoICell = createTextFieldCell(icon: "calendar", title: "NRIC " + NSLocalizedString("DateOfIssue", comment: ""), placeholder: "dd-mmm-yyyy")
        nricDoICell.setAsDatePicker()
        nricDoICell.serverErrorType = .lineOnly
        nricDoICell.onFind = { [weak self] in self?.performSegueId("NRICModal") }

        noteMinorCell = createNoteCell(note: "noteMinor")
        noteNSCell = createNoteCell(note: "noteNS")
        reloadCells()
    }

    override func setupViewForStaticProfile() {
        super.setupViewForStaticProfile()
        cells[0].append(createLabelCell(icon: .card, title: .NRIC, key: .id))
    }

    func reloadCells() {
        cells = [[nameCell, dobCell, nricCell], isMinor ? [noteMinorCell] : [nricDoICell, noteNSCell]]
    }

    func checkDoB() {
        let dobDate = (dobCell.textField.inputView as! UIDatePicker).date
        let calendar = Calendar.appCalendar
        let birthYear = calendar.component(.year, from: dobDate)
        let currentYear = calendar.component(.year, from: Date())
        let isMinor = currentYear - birthYear < 17
        if self.isMinor != isMinor {
            self.isMinor = isMinor
            reloadCells()
            tableView.reloadSections(IndexSet(integer: 2), with: .automatic)
        }
        checkReady()
    }

    func checkNRIC() {
        //Check if user entered FIN instead of NRIC and redirect
        if nricCell.textField.text!.count > 0 && (nricCell.textField.text?.first == "F" || nricCell.textField.text?.first == "G") {
            nricCell.error = NSLocalizedString("TapBackAndSelectFIN", comment: "Please tap back and select a FIN profile")
        } else if nricCell.textField.text!.count > 0 && !NricFinChecker.validNricFin(nricCell.textField.text!, profileType: .NRIC) {
            nricCell.error = NSLocalizedString("InvalidNRIC", comment: "Invalid NRIC")
        } else {
            nricCell.error = nil
        }
        checkReady()
    }
}
