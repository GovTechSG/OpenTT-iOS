//
//  HomeShortcutWidgetViewModel.swift
//  OpenTraceTogether

import UIKit

protocol HomeShortcutWidgetDelegate: AnyObject {
    var lastSafeEntrySessionWithoutCheckout: SafeEntrySession? { get }
    func goToScanQR()
    func viewPass()
    func checkOut()
}

class HomeShortcutWidgetViewModel: NSObject {

    weak var delegate: HomeShortcutWidgetDelegate?

    func viewDidLoad() {
        if #available(iOS 14.0, *) {
            /// When app becomes active, check if user opening app from widget
            NotificationCenter.default.addObserver(self, selector: #selector(handleShortcut), name: UIApplication.didBecomeActiveNotification, object: nil)
            /// When app becomes inactive, reload widget to make sure it is reflecting the current state of SE
            NotificationCenter.default.addObserver(self, selector: #selector(reloadSafeEntryWidget), name: UIApplication.willResignActiveNotification, object: nil)
        }
    }

    func viewDidAppear() {
        if #available(iOS 14.0, *) {
            handleShortcut()
            reloadSafeEntryWidget()
        }
    }

    @available(iOS 14.0, *)
    @objc func reloadSafeEntryWidget() {
        let tenantName = delegate?.lastSafeEntrySessionWithoutCheckout?.tenantName
        let venueName = delegate?.lastSafeEntrySessionWithoutCheckout?.venueName
        let model = WidgetUtils.WidgetModel(
            venueName: SafeEntryUtils.formatSETenantVenueDisplay(tenantName, venueName),
            showCheckIn: SafeEntryUtils.isUserAllowedToSafeEntry(),
            /// Reload the widget in case user forgot to check out after 24 hours
            removeDate: delegate?.lastSafeEntrySessionWithoutCheckout?.checkInDate?.addingTimeInterval(TimeInterval(abs(SafeEntryConfig.TTLHours) * 60 * 60))
        )
        WidgetUtils.reloadWidget(with: model)
    }

    @available(iOS 14.0, *)
    @objc private func handleShortcut() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
              let url = appDelegate.launchUrl,
              let actionType = WidgetUtils.actionType(from: url) else {
            return
        }
        appDelegate.launchUrl = nil

        let mapIdToSelector: [WidgetUtils.ActionType: Selector] = [
            .checkIn: #selector(goToScanQR),
            .viewPass: #selector(viewPass),
            .checkOut: #selector(checkOut)
        ]
        guard let selector = mapIdToSelector[actionType] else {
            return
        }
        perform(selector)
    }

    @objc private func goToScanQR() {
        AnalyticManager.logEvent(eventName: "se_tap_scan_qr", param: ["position": "widget"])
        delegate?.goToScanQR()
    }

    @objc private func viewPass() {
        AnalyticManager.logEvent(eventName: "se_tap_view_pass", param: ["position": "widget"])
        delegate?.viewPass()
    }

    @objc private func checkOut() {
        AnalyticManager.logEvent(eventName: "se_tap_check_out", param: ["position": "widget"])
        delegate?.checkOut()
    }
}
