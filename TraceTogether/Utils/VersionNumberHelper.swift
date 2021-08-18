//
//  VersionNumberHelper.swift
//  OpenTraceTogether

import Foundation

struct VersionNumberHelper {
    static func getCurrentVersion() -> String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    }

    // added in v2.1
    static var appVersionOnViewWhatsNew: String? {
        get {
            return UserDefaults.standard.string(forKey: "appVersionOnViewWhatsNew")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "appVersionOnViewWhatsNew")
        }
    }
    // added in v2.1
    static var appVersionOnRegistration: String? {
        get {
            return UserDefaults.standard.string(forKey: "appVersionOnRegistration")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "appVersionOnRegistration")
        }
    }
}

extension String {
    /// Returns the comparison of two versions - prefix(5) takes the max first 5 characters or fewer of semantic versioning 
    /// i.e. "2.3.4" or "2.4".
    /// Does not work with semantic versioning up to 6 characters, e.g. "2.3.10"
    /// Allows internal debug builds to continue using "2.3.40001" as internal versioning for "2.3.4"

    func isVersionLowerThan(_ comparison: String) -> Bool {
        let selfVersion = self.prefix(5)
        let comparisonVersion = comparison.prefix(5)
        switch comparisonVersion.compare(selfVersion, options: .numeric) {
        case .orderedAscending:
            return false
        case .orderedSame:
            return false
        case .orderedDescending:
            return true
        }
    }

    func isVersionLowerThanOrEqualTo(_ comparison: String) -> Bool {
        let selfVersion = self.prefix(5)
        let comparisonVersion = comparison.prefix(5)
        switch comparisonVersion.compare(selfVersion, options: .numeric) {
        case .orderedAscending:
            return false
        case .orderedSame:
            return true
        case .orderedDescending:
            return true
        }
    }

    func isVersionGreaterThanOrEqualTo(_ comparison: String) -> Bool {
        let selfVersion = self.prefix(5)
        let comparisonVersion = comparison.prefix(5)
        switch comparisonVersion.compare(selfVersion, options: .numeric) {
        case .orderedAscending:
            return true
        case .orderedSame:
            return true
        case .orderedDescending:
            return false
        }
    }

}
