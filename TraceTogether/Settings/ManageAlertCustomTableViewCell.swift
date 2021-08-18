//
//  ManageAlertCustomTableViewCell.swift
//  OpenTraceTogether

import UIKit

class ManageAlertCustomTableViewCell: UITableViewCell {

    @IBOutlet weak var alertTitle: UILabel!
    @IBOutlet weak var alertDescription: UILabel!
    @IBOutlet weak var alertSwitch: UISwitch!

    override func awakeFromNib() {
        super.awakeFromNib()
        //Change size of UISwitch
        alertSwitch.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
