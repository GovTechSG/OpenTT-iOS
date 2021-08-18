//
//  FormFooterCell.swift
//  OpenTraceTogether

import UIKit

class FormFooterCell: UITableViewCell {
    @IBOutlet var checkBoxButton: UIButton!
    @IBOutlet weak var termsAndConditionsTextView: UITextView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet var submitButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.isAccessibilityElement = false
        self.accessibilityElements = [checkBoxButton!, termsAndConditionsTextView!, backButton!, submitButton!]
    }

}
