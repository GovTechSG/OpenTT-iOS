//
//  FormLabelCell.swift
//  OpenTraceTogether

import UIKit

class FormLabelCell: UITableViewCell {

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var valueLabel: UILabel!
    @IBOutlet var iconView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.isAccessibilityElement = false
        if let titleLabel = titleLabel {
            self.accessibilityElements?.append(titleLabel)
        }
        if let valueLabel = valueLabel {
            self.accessibilityElements?.append(valueLabel)

        }
    }

}
