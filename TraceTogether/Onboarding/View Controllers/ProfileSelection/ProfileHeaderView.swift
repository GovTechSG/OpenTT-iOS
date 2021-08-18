//
//  ProfileHeaderView.swift
//  OpenTraceTogether

import UIKit

class ProfileHeaderView: UITableViewHeaderFooterView {

    @IBOutlet weak var headerBackground: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!
    @IBOutlet var titleLabelCenterInContainerConstraint: NSLayoutConstraint?
    @IBOutlet var titleLabelTopConstraint: NSLayoutConstraint?

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        //Add subviews and set up constraints
         commonInit()
    }

    required init?(coder aDecoder: NSCoder) { // for using CustomView in IB
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {

    }

    func setSelected() {
        titleLabel.textColor = UIColor.white
        detailsLabel.textColor = UIColor.white
        headerBackground.backgroundColor = UIColor(hexString: "#FF6565")
        headerBackground.borderColor = UIColor.white
    }

    func setDeselected() {
        titleLabel.textColor = UIColor(hexString: "#BDBDBD")
        detailsLabel.textColor = UIColor(hexString: "#BDBDBD")
        headerBackground.backgroundColor = UIColor(hexString: "#F2F2F2")
        headerBackground.borderWidth = 0
    }

    func setDefaultSelected() {
        titleLabel.textColor = UIColor(hexString: "#333333")
        detailsLabel.textColor = UIColor(hexString: "#333333")
        headerBackground.backgroundColor = UIColor.white
        headerBackground.borderWidth = 1
    }

    func setDefaultDeselected() {
        titleLabel.textColor = UIColor(hexString: "#333333")
        detailsLabel.textColor = UIColor(hexString: "#333333")
        headerBackground.backgroundColor = UIColor.white
        headerBackground.borderWidth = 1
    }
}
