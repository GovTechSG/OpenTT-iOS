//
//  DebugTools.swift
//  OpenTraceTogether

import Foundation
import FirebaseRemoteConfig
import FirebaseAuth

class DebugTools {
    static func isDebug() -> Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    static func isInternalRelease() -> Bool {
        #if INTERNALRELEASE
        return true
        #else
        return false
        #endif
    }
}

struct DebugConfig {
    static var notifier: (() -> Void)?
    static var getZeroExposures: Bool = false {
        didSet {
            notifier?()
        }
    }
}
