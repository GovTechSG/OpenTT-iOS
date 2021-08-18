//
//  HomeHistoryViewModel.swift
//  OpenTraceTogether

import Foundation
import UIKit
import Network

enum ExposureCardStates: String {
    case loading
    case noInternet
    case serverUnavailable
    case noExposures
    case possibleExposures
    case hideCard
}

@objc protocol HomeHistoryCardDelegate: NSObjectProtocol {
    func hideAllCards()
    func showLoadingCard()
    func showNoInternetCard()
    func showServerUnavailableCard()
    func showPossibleExposuresCard()
    func showNoExposuresCard()
    func adjustViewMarginsBasedOnConfigFlag(_ showCard: Bool)
}

class HomeHistoryViewModel: NSObject {
    weak var cardDelegate: HomeHistoryCardDelegate?
    var showCard: Bool {
        return RemoteConfigManager.shared.togglePossibleExposure && SafeEntryUtils.isUserAllowedToSafeEntry()
    }

    required init(_ delegate: HomeHistoryCardDelegate) {
        super.init()
        self.cardDelegate = delegate
        if showCard == true {
            currentExposureCardState = .loading
            registerForNotification()
        } else {
            currentExposureCardState = .hideCard
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    var currentExposureCardState: ExposureCardStates = .hideCard {
        didSet {
            HistoryExposureController.shared.currentExposureCardState = currentExposureCardState
            self.cardDelegate?.hideAllCards()
            self.cardDelegate?.adjustViewMarginsBasedOnConfigFlag(self.showCard)
            switch self.currentExposureCardState {
            case .hideCard:
                print("Hide possible exposures card")
            case .loading:
                self.cardDelegate?.showLoadingCard()
            case .noInternet:
                self.cardDelegate?.showNoInternetCard()
            case .serverUnavailable:
                self.cardDelegate?.showServerUnavailableCard()
            case .noExposures:
                self.cardDelegate?.showNoExposuresCard()
            case .possibleExposures:
                self.cardDelegate?.showPossibleExposuresCard()
            }
        }
    }

    func registerForNotification() {
        RemoteConfigManager.shared.addObserver(self, selector: #selector(reloadView))

        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        if let reachability = appDelegate.reachability {
            NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged), name: Notification.Name.reachabilityChanged, object: reachability )
            showCardForReachibilityState(connection: reachability.connection)
        }

        NotificationCenter.default.addObserver(self, selector: #selector(fetchHistoryRecords), name: UIApplication.willEnterForegroundNotification, object: nil)

        #if DEBUG
        DebugConfig.notifier = {
            print("Debug configuration changed")
            HistoryExposureController.exposuresLastUpdated = Calendar.appCalendar.date(byAdding: .hour, value: -24, to: Date())
            self.fetchHistoryRecords()
        }

        NotificationCenter.default.addObserver(self, selector: #selector(fetchHistoryRecords), name: NSNotification.Name(rawValue: "DebugConfigurationChanged"), object: nil)
        #endif

    }
}

extension HomeHistoryViewModel {
    func onViewDidAppear() {
        if showCard == true {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                return
            }
            if let reachability = appDelegate.reachability {
                showCardForReachibilityState(connection: reachability.connection)
            }
        } else {
            currentExposureCardState = .hideCard
        }
    }

    @objc func reachabilityChanged( notification: NSNotification ) {
        guard let reachability = notification.object as? Reachability else {
            return
        }
        showCardForReachibilityState(connection: reachability.connection)
    }

    func showCardForReachibilityState(connection: Reachability.Connection) {
        currentExposureCardState = .loading
        if connection != .unavailable {
            print("We're connected!")
            self.fetchHistoryRecords()
        } else {
            print("Network not reachable")
            if HistoryExposureController.exposuresHaveExpired() {
                self.currentExposureCardState = .noInternet
                HistoryExposureController.shared.exposures = []
                print("No internet, and existing data has expired")
            } else {
                // No internet, and existing data has not expired
                self.fetchHistoryRecords()
                print("No internet, and existing data has not expired")
            }
        }
    }

    @objc func fetchHistoryRecords() {
        print("HomeHistoryCardController - fetchHistoryRecords")
        self.currentExposureCardState = .loading
        HistoryExposureController.shared.fetchData { [weak self] error in
            if let error = error {
                if error == ExposuresFetchError.noInternet.rawValue {
                    self?.currentExposureCardState = .noInternet
                } else {
                    print("fetchHistoryRecords - serverUnavailable")
                    self?.currentExposureCardState = .serverUnavailable
                }
            } else {
                self?.reloadView()
            }
        }
    }

    @objc func reloadView() {
        print("HomeHistoryCardController - reloadView")

        #if DEBUG
        if DebugConfig.getZeroExposures {
            HistoryExposureController.shared.exposures = []
        }
        #endif
        let gotExposure = HistoryExposureController.shared.exposures.count > 0
        cardDelegate?.adjustViewMarginsBasedOnConfigFlag(showCard)
        if showCard == true {
            self.currentExposureCardState = gotExposure ? .possibleExposures : .noExposures
        } else {
            self.currentExposureCardState = .hideCard
        }
    }

}
