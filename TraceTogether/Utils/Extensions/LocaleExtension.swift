//
//  LocaleExtension.swift
//  OpenTraceTogether

import UIKit

extension Locale {

    static var appLocale: Locale {
        return Locale(identifier: "en_US_POSIX")
    }

    static func isoCode(from countryName: String?) -> String? {
        guard let countryName = countryName else {
            return nil
        }
        return Locale.isoRegionCodes.first(where: { (code) -> Bool in
            Locale.countryName(from: code)?.compare(countryName, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        })
    }

    static func countryName(from isoCode: String?) -> String? {
        return Locale.appLocale.localizedString(forRegionCode: isoCode ?? "")
    }

    static var countryNames: [String] {
        return Locale.isoRegionCodes.map { countryName(from: $0) ?? $0 }.sorted().filter({$0 != "Singapore"})
    }
}
