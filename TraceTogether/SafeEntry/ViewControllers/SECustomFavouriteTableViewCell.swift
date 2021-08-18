//
//  SECustomFavouriteTableViewCell.swift
//  OpenTraceTogether

import UIKit

class SECustomFavouriteTableViewCell: UITableViewCell {

    @IBOutlet weak var venueNameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var starButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.isAccessibilityElement = false
        self.accessibilityElements = [venueNameLabel!, addressLabel!, starButton!]
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
