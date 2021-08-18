//
//  WidgetUtils.swift
//  OpenTraceTogether

import Foundation
import WidgetKit

/**
 WIDGET and MAIN target talk using` deeplink://` and `userDefaults`, so need to have a shared class that bridge both target.
 */
@available(iOS 14.0, *)
struct WidgetUtils {

    struct WidgetModel: Codable {
        let venueName: String
        let showCheckIn: Bool
        let removeDate: Date?
    }

    enum ActionType: String {
        case checkIn = "CheckIn"
        case checkOut = "CheckOut"
        case viewPass = "ViewPass"
    }

    /// To shared data between WIDGET and MAIN target, they need to have a shared `userDefaults`.
    /// `suiteName` is a random name, but need to match .entitlements
    static let userDefaults = UserDefaults(suiteName: "group.xx.xxx.xxx")

    /// MAIN target need to pass data to WIDGET. It is stored in `userDefaults` (decoded to `NSData`) with this key
    static let widgetDataUserDefaultsKey = "WidgetUtils.WidgetData"

    static func reloadWidget(with widgetModel: WidgetModel) {
        if let data = try? JSONEncoder().encode(widgetModel) {
            userDefaults?.set(data, forKey: widgetDataUserDefaultsKey)
            reloadAllWidget()
        }
    }

    static func reloadAllWidget() {
        /// Currently it can't compile unless we hack it this way
        #if arch(arm64) || arch(i386) || arch(x86_64)
            WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    static func getWidgetModel(from data: Data) -> WidgetModel {
        return (try? JSONDecoder().decode(WidgetModel.self, from: data)) ??
            WidgetModel(venueName: "", showCheckIn: false, removeDate: nil)
    }

    static func url(from actionType: ActionType) -> URL {
        return URL(string: "widget://\(actionType.rawValue)")!
    }

    static func actionType(from url: URL) -> ActionType? {
        return url.scheme == "widget" ? ActionType(rawValue: url.host ?? "") : nil
    }
}
