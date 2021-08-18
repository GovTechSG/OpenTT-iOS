//
//  HomeShortcutSiriViewModel.swift
//  OpenTraceTogether

import Foundation
import UIKit

protocol HomeShortcutSiriDelegate: AnyObject {
    func goToScanQR()
    func goToFavourites()
    func goToGroupCheckIn()
    func checkOut()
}

class HomeShortcutSiriViewModel: NSObject {

    weak var delegate: HomeShortcutSiriDelegate?

    func viewDidLoad() {
        /// When app becomes active, check if user opening app from siri shortcut
        NotificationCenter.default.addObserver(self, selector: #selector(handleShortcut), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    func viewDidAppear() {
        handleShortcut()
    }

    @objc private func handleShortcut() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        guard let launchId = appDelegate.userActivityType else {
            return
        }
        appDelegate.userActivityType = nil

        let mapIdToSelector: [String: Selector] = [
            SiriShortcutModel.kScanQRId: #selector(goToScanQR),
            SiriShortcutModel.kFavouritesCheckInId: #selector(goToFavourites),
            SiriShortcutModel.kGroupCheckInId: #selector(goToGroupCheckIn),
            SiriShortcutModel.kCheckOutId: #selector(checkOut)
        ]
        guard let selector = mapIdToSelector[launchId] else {
            return
        }
        perform(selector)
    }

    @objc private func goToScanQR() {
        AnalyticManager.logEvent(eventName: "se_tap_scan_qr", param: ["position": "siri"])
        delegate?.goToScanQR()
    }

    @objc private func goToFavourites() {
        AnalyticManager.logEvent(eventName: "se_tap_favourites_check_in", param: ["position": "siri"])
        delegate?.goToFavourites()
    }

    @objc private func goToGroupCheckIn() {
        AnalyticManager.logEvent(eventName: "se_tap_group_check_in", param: ["position": "siri"])
        delegate?.goToGroupCheckIn()
    }

    @objc private func checkOut() {
        AnalyticManager.logEvent(eventName: "se_tap_check_out", param: ["position": "siri"])
        delegate?.checkOut()
    }
}
