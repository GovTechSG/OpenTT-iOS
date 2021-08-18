//
//  HomeHistoryCardController.swift
//  OpenTraceTogether

import UIKit
import Network

class HomeHistoryCardController: UIViewController {

    @IBOutlet var exposureGreenCard: UIButton!
    @IBOutlet var exposureRedCard: UIButton!
    @IBOutlet var topMarginConstraint: NSLayoutConstraint!
    @IBOutlet var lottieBottomMarginConstraint: NSLayoutConstraint!
    @IBOutlet weak var exposureMessageCard: UIView!
    @IBOutlet weak var exposureLoadingCard: UIView!
    @IBOutlet weak var exposureSkeletonViewOne: SkeletonView!
    @IBOutlet weak var exposureSkeletonViewTwo: SkeletonView!
    @IBOutlet weak var exposureMessageLabel: UILabel!
    var homehistoryViewModel: HomeHistoryViewModel!

    override func viewDidLoad() {
        super.viewDidLoad()
        homehistoryViewModel = HomeHistoryViewModel(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        homehistoryViewModel.onViewDidAppear()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    @IBAction func gotoHistoryPossibleExposures(_ sender: UIButton) {
        AnalyticManager.logEvent(eventName: "se_tap_exposure_card", param: ["position": "home_page_cards"])
        tabBarController!.selectedIndex = 1
        let historyNavController = tabBarController!.children[1] as! UINavigationController
        let historyController = historyNavController.children.first as! HistoryMasterViewController
        historyController.loadViewIfNeeded()
        historyController.childTabBarController.selectedIndex = 1
    }
}

extension HomeHistoryCardController: HomeHistoryCardDelegate {
    func hideAllCards() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            self.exposureGreenCard.isHidden = true
            self.exposureRedCard.isHidden = true
            self.exposureMessageCard.isHidden = true
            self.exposureLoadingCard.isHidden = true
            self.exposureSkeletonViewOne.stopAnimating()
            self.exposureSkeletonViewTwo.stopAnimating()
        }
    }

    func showLoadingCard() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            self.exposureLoadingCard.isHidden = false
            self.exposureSkeletonViewOne.startAnimating()
            self.exposureSkeletonViewTwo.startAnimating()
        }
    }

    func showNoInternetCard() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            self.exposureMessageCard.isHidden = false
            self.exposureMessageLabel.text = NSLocalizedString("NoInternetConnectToSeeSEStatus", comment: "")
        }
    }

    func showServerUnavailableCard() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            self.exposureMessageCard.isHidden = false
            self.exposureMessageLabel.text = NSLocalizedString("ExposureCheckTemporarilyUnavailable", comment: "")
        }
    }

    func showPossibleExposuresCard() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            self.exposureRedCard.isHidden = false
        }
    }

    func showNoExposuresCard() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            self.exposureGreenCard.isHidden = false
        }
    }

    func adjustViewMarginsBasedOnConfigFlag(_ showCard: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            self.topMarginConstraint.constant = showCard ? -24 : 24
            self.lottieBottomMarginConstraint.constant = showCard ? 8 : -16
        }
    }
}
