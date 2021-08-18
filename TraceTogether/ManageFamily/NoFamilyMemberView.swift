//
//  NoFamilyMemberView.swift
//  OpenTraceTogether

import UIKit

protocol NoFamilyMemberDelegate: class {
    func addFamilyMemberButtonTapped()
}

class NoFamilyMemberView: UIView {

    @IBOutlet var noFamilyMemberContentView: UIView!
    @IBOutlet weak var addFamilyMembersBtn: UIButton!

    weak var delegate: NoFamilyMemberDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        noFamilyMemberCommonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        noFamilyMemberCommonInit()
    }

    override func layoutSubviews() {
        addFamilyMembersBtn.cornerRadius = 20.0
    }

    private func noFamilyMemberCommonInit() {
        Bundle.main.loadNibNamed("NoFamilyMemberView", owner: self, options: nil)
        addSubview(noFamilyMemberContentView)
        noFamilyMemberContentView.frame = self.bounds
        noFamilyMemberContentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    @IBAction func addFamilyMembers(_ sender: UIButton) {
        delegate?.addFamilyMemberButtonTapped()
    }
}
