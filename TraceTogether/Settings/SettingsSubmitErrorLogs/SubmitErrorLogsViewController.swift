//
//  SubmitErrorLogsViewController.swift
//  OpenTraceTogether

import UIKit

class SubmitErrorLogsViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = NSLocalizedString("SubmitErrorLogs", comment: "")
    }
    @IBAction func submitErrorLogsBtnPressed(_ sender: UIButton) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate, let reachability = appDelegate.reachability,
              reachability.connection != .unavailable else {
            showAlertWithMessage(NSLocalizedString("CheckConnectionTryAgain", comment: "Check your connection and try again."), message: NSLocalizedString("ThereSeemsNetworkIssue", comment: "There seems to be a network issue."))
            return
        }

        //Log necessary info before submitting
        LogMessage.logBluetrace()
        LoadingViewController.present(in: self)

        StorageAPIs.uploadAllCollectableLogs { (error) in
            LoadingViewController.dismiss(in: self) {
                if let error = error {
                    let vc = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                    vc.addAction(.init(title: "Dismiss", style: .cancel, handler: nil))
                    self.present(vc, animated: true, completion: nil)
                    LogMessage.create(type: .Error, title: #function, details: "\(error.localizedDescription)")
                } else {
                    let vc = self.storyboard!.instantiateViewController(withIdentifier: "ErrorLogsSubmittedSuccessfullyViewController") as! ErrorLogsSubmittedSuccessfullyViewController
                    let vcs = self.navigationController!.viewControllers.map { $0 == self ? vc : $0 }
                    self.navigationController!.setViewControllers(vcs, animated: true)
                }
            }
        }
    }
}
