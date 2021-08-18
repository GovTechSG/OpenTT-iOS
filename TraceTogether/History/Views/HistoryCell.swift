//
//  HistoryCell.swift
//  OpenTraceTogether

import UIKit

class HistoryCell: UITableViewCell {

    static let timeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "h:mma"
        df.locale = Locale(identifier: "en_SG")

        return df
    }()

    @IBOutlet var titleLabel: UILabel?
    @IBOutlet var detailLabel: UILabel?
    @IBOutlet var stackView: UIStackView?
    @IBOutlet var customAccessoryView: UIView?
    @IBOutlet var checkOutButton: UIButton?

    func set(checkInDate: Date?, checkOutDate: Date?, showCheckoutOption: Bool = false) {
        let startTime = HistoryCell.timeFormatter.string(for: checkInDate) ?? NSLocalizedString("NoCheckIn", comment: "")
        let endTime = HistoryCell.timeFormatter.string(for: checkOutDate) ?? NSLocalizedString("NoCheckOut", comment: "No check out")
        detailLabel?.text = showCheckoutOption ? "\(startTime)" : "\(startTime) - \(endTime)"

        let to = NSLocalizedString("To", comment: "To")
        let checkInTime = NSLocalizedString("CheckInTime", comment: "CheckInTime")
        let checkOutTime = NSLocalizedString("CheckOutTime", comment: "CheckOutTime")
        if endTime != "No check out" {
            detailLabel?.accessibilityLabel = "\(startTime) \(checkInTime) \(to) \(endTime) \(checkOutTime)"
        } else {
            detailLabel?.accessibilityLabel = "\(startTime) \(checkInTime) \(to) \(endTime)"
        }

        showCheckoutOption ? showCheckoutButton() : hideCheckoutButton()
    }

    func showCheckoutButton() {
        checkOutButton?.isHidden = false
        checkOutButton?.isEnabled = true
    }

    func hideCheckoutButton() {
        checkOutButton?.isHidden = true
        checkOutButton?.isEnabled = false
    }

}
