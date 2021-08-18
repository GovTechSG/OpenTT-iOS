//
//  NoPossibleExposureViewController.swift
//  OpenTraceTogether

import UIKit
import SafariServices

class NoPossibleExposureViewController: UIViewController {

    @IBOutlet weak var howPossibleExposuresDeterminedButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        howPossibleExposuresDeterminedButton.titleLabel?.numberOfLines = 0
        howPossibleExposuresDeterminedButton.titleLabel?.lineBreakMode = .byWordWrapping
    }

    @IBAction func gotoPossibleExposuresInfo(_ sender: Any) {
        let vc = SFSafariViewController(url: URL(string: "https://support.tracetogether.gov.sg/hc/en-sg/articles/360053464873-How-are-my-possible-exposures-determined-")!)
        present(vc, animated: true)

    }

}
