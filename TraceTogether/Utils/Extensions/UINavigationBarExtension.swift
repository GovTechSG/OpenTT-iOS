//
//  UINavigationBarExtension.swift
//  OpenTraceTogether

import UIKit

/// Use this class to have a custom navigation back image
class TTNavigationBar: UINavigationBar {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        applyAppAppearance()
        items?.forEach { $0.applyAppAppearance() }
    }

    override func pushItem(_ item: UINavigationItem, animated: Bool) {
        item.applyAppAppearance()
        super.pushItem(item, animated: animated)
    }
}

extension UINavigationBar {
    func applyAppAppearance() {
        let backImage = UIImage(named: "navigationback")
        backIndicatorImage = backImage
        backIndicatorTransitionMaskImage = backImage
        tintColor = UIColor(hexString: "#333333")
    }
}

extension UINavigationItem {
    func applyAppAppearance() {
        backBarButtonItem = .init()
        backBarButtonItem?.title = " "
        backBarButtonItem?.accessibilityLabel = "Back"
    }
}
