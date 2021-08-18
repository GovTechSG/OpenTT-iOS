//
//  HomeQuickLaunchViewModel.swift
//  OpenTraceTogether

import UIKit

protocol HomeShortcutQuickLaunchDelegate: AnyObject {
    func goToScanQR()
}

class HomeShortcutQuickLaunchViewModel: NSObject {

    weak var delegate: HomeShortcutQuickLaunchDelegate?

    func viewDidLoad() {
        /// When app becomes active, check if user opening app from long press
        NotificationCenter.default.addObserver(self, selector: #selector(handleShortcut), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    func viewDidAppear() {
        handleShortcut()
    }

    @objc private func handleShortcut() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        guard let launchId = appDelegate.shortcutItemType,
              let bundle = Bundle.main.bundleIdentifier else {
            return
        }
        appDelegate.shortcutItemType = nil

        let mapIdToSelector: [String: Selector] = [
            "\(bundle).safeEntry": #selector(goToScanQR)
        ]
        guard let selector = mapIdToSelector[launchId] else {
            return
        }
        perform(selector)
    }

    @objc private func goToScanQR() {
        AnalyticManager.logEvent(eventName: "se_tap_scan_qr", param: ["position": "quicklaunch"])
        delegate?.goToScanQR()
    }
}
