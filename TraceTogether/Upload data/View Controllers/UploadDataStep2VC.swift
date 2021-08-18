//
//  UploadDataStep2VC.swift
//  OpenTraceTogether

import Foundation
import UIKit

class UploadDataStep2VC: UIViewController {
    @IBOutlet weak var uploadErrorMsgLbl: UILabel!
    @IBOutlet weak var uploadCodeField: UITextField!

    override func viewDidLoad() {
        uploadErrorMsgLbl.text = ""
        dismissKeyboardOnTap()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        _ = uploadCodeField.becomeFirstResponder()
        AnalyticManager.setScreenName(screenName: "UploadScreenPin", screenClass: "UploadDataStep2VC")
    }

    @IBAction func noUploadCodeOnPress() {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func uploadDataOnPress() {
        uploadErrorMsgLbl.text = ""
        uploadCodeField.resignFirstResponder()
        LoadingViewController.present(in: self)

        StorageAPIs.uploadAllEncounter(uploadCode: uploadCodeField.text!) { error in
            // no need [weak self] as VC can't be dismissed (loadingVC overlaying the entire screen)
            LoadingViewController.dismiss(in: self) {
                if let error = error {
                    self.uploadErrorMsgLbl.text = error.localizedDescription
                } else {
                    self.performSegue(withIdentifier: "showSuccessVCSegue", sender: nil)
                }
            }
        }
    }
}
