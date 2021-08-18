//
//  FavMessageViewController.swift
//  OpenTraceTogether

import UIKit
import Photos

class FavMessageViewController: UIViewController {

    @IBOutlet weak var normalSEFlowFavIcon: UIImageView!
    @IBOutlet weak var groupCheckInSEFlowFavIcon: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        if UserDefaults.standard.bool(forKey: "groupCheckInFlowToHandleHowToUse") {
            groupCheckInSEFlowFavIcon.isHidden = false
        } else {
            normalSEFlowFavIcon.isHidden = false
        }
    }

    @IBAction func favAwesomeBtnPressed(_ sender: UIButton) {
        if UserDefaults.standard.bool(forKey: "groupCheckInFlowToHandleHowToUse") {
            self.navigationController?.dismiss(animated: false, completion: nil)
            UserDefaults.standard.set(true, forKey: "UserHasUnderstoodHowQRScanningWorks")
        }
    }
}
