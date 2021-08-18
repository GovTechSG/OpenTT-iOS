//
//  UIAlertControllerExtension.swift
//  OpenTraceTogether

import UIKit

extension UIAlertController {

    static func noInternetAlertController(_ retryBlock: (() -> Void)? = nil) -> UIAlertController {
        let title = NSLocalizedString("CheckYourConnection", comment: "")
        let message = NSLocalizedString("CheckYourConnectionMessage", comment: "")
        let retry = NSLocalizedString("Retry", comment: "")
        let cancel = NSLocalizedString("Cancel", comment: "")
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(.init(title: cancel, style: .cancel))
        if retryBlock != nil {
            alert.addAction(.init(title: retry, style: .default) { _ in retryBlock?() })
        }
        return alert
    }

    static func temporarilyUnavailableAlertController() -> UIAlertController {
        let title = NSLocalizedString("TemporarilyUnavailable", comment: "")
        let message = NSLocalizedString("TemporarilyUnavailableMessage", comment: "")
        let cancel = NSLocalizedString("OK", comment: "")
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(.init(title: cancel, style: .cancel))
        return alert
    }
}
