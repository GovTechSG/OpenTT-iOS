//
//  PermissionsUtils.swift
//  OpenTraceTogether

import Foundation

class PermissionsUtils {
    static func isAllPermissionsAuthorized() -> Bool {
        return isBluetoothAuthorized() && isPushNotificationsAuthorised()
    }
    static func isBluetoothOn() -> Bool {
        return BluetraceManager.shared.isBluetoothOn()
    }
    static func isBluetoothResettingOrUnknown() -> Bool {
        return BluetraceManager.shared.isBluetoothResettingOrUnknown()
    }
    static func isBluetoothAuthorized() -> Bool {
        return BluetraceManager.shared.isBluetoothAuthorized()
    }
    static func isPushNotificationsAuthorised() -> Bool {
        return BlueTraceLocalNotifications.shared.checkAuthorization()
    }
}
