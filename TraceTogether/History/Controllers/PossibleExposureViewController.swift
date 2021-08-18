//
//  PossibleExposureViewController.swift
//  OpenTraceTogether

import UIKit
import SafariServices

class PossibleExposureViewController: UIViewController {

    @IBOutlet var noExposureView: UIView!
    @IBOutlet var exposureView: UIView!
    @IBOutlet var noInternetServerUnavailableView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(updateUIBasedOnExposuresCardState), name: ExposureCardStateUpdatedNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUIBasedOnExposuresCardState()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func updateUIBasedOnExposuresCardState() {
        noInternetServerUnavailableView.isHidden = false
        noExposureView.isHidden = true
        exposureView.isHidden = true
        switch HistoryExposureController.shared.currentExposureCardState {
        case .hideCard:
            print("hide card")
        case .loading, .noInternet, .serverUnavailable:
            noInternetServerUnavailableView.isHidden = false
            noExposureView.isHidden = true
            exposureView.isHidden = true
        case .noExposures:
            noInternetServerUnavailableView.isHidden = true
            noExposureView.isHidden = false
            exposureView.isHidden = true
        case .possibleExposures:
            noInternetServerUnavailableView.isHidden = true
            noExposureView.isHidden = true
            exposureView.isHidden = false
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let historyRecordsVC = segue.destination as? HistoryRecordsViewController {
            historyRecordsVC.showAllRecords = false
        }
    }
}
