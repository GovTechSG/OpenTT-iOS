//
//  NumberFormatterExtension.swift
//  OpenTraceTogether

import UIKit

extension NumberFormatter {
    /// Convert number to decimal string. e.g. `1000` to `1.000`
    static func decimalString(fromNumber number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale.appLocale
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number))!
    }
}
