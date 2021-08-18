//
//  RadioCell.swift
//  OpenTraceTogether

import UIKit

class FormRadioCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var option1Button: UIButton!
    @IBOutlet var option2Button: UIButton!

    lazy var optionButtons: [UIButton]! = [option1Button, option2Button]
    var valueChanged: (() -> Void)?

    @IBAction func buttonPressed(_ sender: UIButton) {
        optionButtons.forEach { $0.isSelected = $0 == sender }
        valueChanged?()
    }
}
