//
//  SettingsCustomTableViewCell.swift
//  OpenTraceTogether

import UIKit

class SettingsCustomTableViewCell: UITableViewCell {

    @IBOutlet weak var settingCellTitleLabel: UILabel!
    @IBOutlet weak var settingNewLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        settingNewLabel.layer.masksToBounds = true
        self.isAccessibilityElement = false
        self.accessibilityElements = [settingCellTitleLabel!, settingNewLabel!]
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    override func layoutSubviews() {
        settingNewLabel.layer.cornerRadius = 4.0
    }
}
