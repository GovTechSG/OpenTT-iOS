//
//  DataKeptSecureViewController.swift
//  OpenTraceTogether

import UIKit

class DataKeptSecureViewController: UIViewController {

    @IBOutlet weak var dataKeptSecureLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        closeButton.accessibilityLabel = NSLocalizedString("Close", comment: "Close")

        dataKeptSecureLabel.attributedText = Markup.getAttributedString(markupString: NSLocalizedString("DataKeptSecure", comment: ""), font: UIFont.systemFont(ofSize: 16))
    }

    @IBAction func closeAction(_ sender: UIButton) {
        dismiss(animated: false, completion: nil)
    }

}
