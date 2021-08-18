//
//  CommonOverlayViewController.swift
//  OpenTraceTogether

import UIKit

class CommonOverlayViewController: UIViewController {
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var defaultButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        closeButton.accessibilityLabel = NSLocalizedString("Close", comment: "Close")
    }

    @IBAction func closeAction(_ sender: UIButton) {
        dismiss(animated: false, completion: nil)
    }

    func setContent(_ text: NSAttributedString) {
        contentLabel.attributedText = text
    }

    func setButtonTitle(_ text: String) {
        defaultButton.setTitle(text, for: .normal)
    }

}
