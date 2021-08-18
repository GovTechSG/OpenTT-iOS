//
//  FormAccessoryView.swift
//  OpenTraceTogether

import UIKit

class FormAccessoryView: UIToolbar {

    var fields: [UIResponder] = []

    @IBAction func prevButtonPressed() {
        if let index = fields.firstIndex(where: { $0.isFirstResponder }), index > 0 {
            fields[0...(index - 1)].last(where: { $0.canBecomeFirstResponder })?.becomeFirstResponder()
        }
    }

    @IBAction func nextButtonPressed() {
        if let index = fields.firstIndex(where: { $0.isFirstResponder }), index < fields.count - 1 {
            fields[(index + 1)...(fields.count - 1)].first(where: { $0.canBecomeFirstResponder })?.becomeFirstResponder()
        } else {
            doneButtonPressed()
        }
    }

    @IBAction func doneButtonPressed() {
        fields.forEach { $0.resignFirstResponder() }
    }
}
