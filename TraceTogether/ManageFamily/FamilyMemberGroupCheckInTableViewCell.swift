//
//  FamilyMemberGroupCheckInTableViewCell.swift
//  OpenTraceTogether

import UIKit

protocol ManageFamilyMemberGroupCheckInDelegate: class {
    func selectFamilyMember(_ sender: FamilyMemberGroupCheckInTableViewCell)
}

class FamilyMemberGroupCheckInTableViewCell: UITableViewCell {

    weak var delegate: ManageFamilyMemberGroupCheckInDelegate?

    @IBOutlet weak var familyMemberImageView: UIImageView!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var nricFinLabel: UILabel!
    @IBOutlet weak var selectFamilyMemberButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.isAccessibilityElement = false
        self.accessibilityElements = [nicknameLabel!, nricFinLabel!, selectFamilyMemberButton!]
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    @IBAction func selectFamilyMemberButtonPressed(_ sender: UIButton) {
        delegate?.selectFamilyMember(self)
    }

}
