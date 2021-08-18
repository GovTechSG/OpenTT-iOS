//
//  UITabBarItemExtension.swift
//  OpenTraceTogether

import UIKit

extension UITabBarItem {

    @IBInspectable var localizedAccessibilityLabel: String! {
        get { return accessibilityLabel }
        set { accessibilityLabel = NSLocalizedString(newValue, comment: newValue) }
    }

    func applyAppAppearance() {
        setBadgeTextAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12.0, weight: .regular)], for: .normal)
        badgeColor = UIColor(red: 255.0/255.0, green: 101.0/255.0, blue: 101.0/255.0, alpha: 1.0)
    }

    public var isNew: Bool {
        get { badgeValue != nil }
        set { badgeValue = newValue ? NSLocalizedString("New", comment: "NEW") : nil
            accessibilityValue = badgeValue?.lowercased() //Setting accessibility value for badge 
            }
        }
    }
