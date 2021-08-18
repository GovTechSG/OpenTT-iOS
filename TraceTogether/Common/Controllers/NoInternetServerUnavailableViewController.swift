//
//  NoInternetServerUnavailableViewController.swift
//  OpenTraceTogether

import UIKit

class NoInternetServerUnavailableViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var detailsLabel: UILabel?
    @IBOutlet weak var exposureSkeletonViewOne: SkeletonView?
    @IBOutlet weak var exposureSkeletonViewTwo: SkeletonView?

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(updateUIBasedOnExposuresCardState), name: ExposureCardStateUpdatedNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("NoInternetServerUnavailable - viewWillAppear")
        updateUIBasedOnExposuresCardState()
    }

    @objc func updateUIBasedOnExposuresCardState() {
        switch HistoryExposureController.shared.currentExposureCardState {
        case .noInternet:
            self.showMessage(mainText: NSLocalizedString("NoInternetConnection", comment: ""), subText: NSLocalizedString("ConnectToSeeCovid19Exposures", comment: ""))
        case .serverUnavailable:
            self.showMessage(mainText: NSLocalizedString("ExposureCheckTemporarilyUnavailableShort", comment: ""), subText: NSLocalizedString("TryAgainLater", comment: ""))
        default:
            self.showLoadingView()
        }
    }

    func showLoadingView() {
        exposureSkeletonViewOne?.isHidden = false
        exposureSkeletonViewTwo?.isHidden = false
        exposureSkeletonViewOne?.startAnimating()
        exposureSkeletonViewTwo?.startAnimating()
        titleLabel?.isHidden = true
        detailsLabel?.isHidden = true
    }

    func showMessage(mainText: String, subText: String) {
        exposureSkeletonViewOne?.stopAnimating()
        exposureSkeletonViewTwo?.stopAnimating()
        exposureSkeletonViewOne?.isHidden = true
        exposureSkeletonViewTwo?.isHidden = true
        titleLabel?.isHidden = false
        detailsLabel?.isHidden = false
        titleLabel?.text = mainText
        detailsLabel?.text = subText
    }

}
