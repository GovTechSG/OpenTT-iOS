//
//  SECustomTableViewCell.swift
//  OpenTraceTogether

import UIKit

class SECustomTableViewCell: UITableViewCell {

    @IBOutlet weak var venueNameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var starButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.isAccessibilityElement = false
        self.accessibilityElements = [venueNameLabel!, addressLabel!, starButton!]
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
