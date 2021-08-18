//
//  AnalyticManager.swift
//  OpenTraceTogether

import UIKit
import FirebaseAnalytics

class AnalyticManager {

    static func setScreenName (screenName: String, screenClass: String, details: [String: String]? = nil) {
        LogMessage.create(type: .Info, title: "Set Screen: \(screenName) \(screenClass)", details: details ?? [:], collectable: true)

        #if RELEASE
        Analytics.setScreenName(screenName, screenClass: screenClass)
        #endif
    }
    static func logEvent(eventName: String, param: [String: String]?) {
        #if RELEASE
        Analytics.logEvent(eventName, parameters: param)
        #endif
    }

    static func logEvent(type: LogMessage.LogType = .Info, eventName: String, param: [String: String]?) {
        LogMessage.create(type: type, title: eventName, details: nil, collectable: true)

        #if RELEASE
        Analytics.logEvent(eventName, parameters: param)
        #endif
    }

}
