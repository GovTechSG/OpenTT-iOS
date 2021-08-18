//
//  IDScanMessageViewController.swift
//  OpenTraceTogether

import UIKit
import Photos

class IDScanMessageViewController: UIViewController {

    @IBOutlet weak var idScanMessageLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        idScanMessageLabel.text = NSLocalizedString("IdScanMessage", comment: "Use your digital barcode instead!\nDo note that older scanners may not read barcodes from phone.")
    }

    @IBAction func closeAction() {
        //Camera
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { response in
            if response {
                //access granted
                DispatchQueue.main.async {
                  self.navigationController?.dismiss(animated: false, completion: nil)
                }
            } else {
                DispatchQueue.main.async {
                    self.navigationController?.dismiss(animated: false, completion: nil)
                    print("permission not given")
                }
            }
        }
        UserDefaults.standard.set(true, forKey: "UserHasUnderstoodHowQRScanningWorks")
    }
}
