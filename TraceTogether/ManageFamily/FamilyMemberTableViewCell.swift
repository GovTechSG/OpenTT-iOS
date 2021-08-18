//
//  FamilyMemberTableViewCell.swift
//  OpenTraceTogether

import UIKit

protocol ManageFamilyMemberDelegate: class {
    func removeFamilyMember(_ sender: FamilyMemberTableViewCell)
}

class FamilyMemberTableViewCell: UITableViewCell {

    weak var delegate: ManageFamilyMemberDelegate?

    @IBOutlet weak var familyMemberImageView: UIImageView!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var nricFinLabel: UILabel!
    @IBOutlet weak var removeFamilyMemberButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.isAccessibilityElement = false
        self.accessibilityElements = [nicknameLabel!, nricFinLabel!, removeFamilyMemberButton!]
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    @IBAction func removeFamilyMemberBtnPressed(_ sender: UIButton) {
        delegate?.removeFamilyMember(self)
    }
}
