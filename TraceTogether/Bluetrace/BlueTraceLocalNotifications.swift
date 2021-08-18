//
//  BlueTraceLocalNotifications.swift
//  OpenTraceTogether

import Foundation
import UIKit

class BlueTraceLocalNotifications: NSObject {

    static let shared = BlueTraceLocalNotifications()

    func initialConfiguration() {
        UNUserNotificationCenter.current().delegate = self
        /* Uncomment to trigger bluetooth state push notification
        setupBluetoothPNStatusCallback() */
    }

    func requestAuthorization() {
        LogMessage.create(type: .Info, title: "\(#function)", details: "", collectable: true)

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            let newState = granted ? 1 : -1
            if newState != UserDefaults.standard.integer(forKey: "pnPermissionsState") {
                UserDefaults.standard.set(newState, forKey: "pnPermissionsState")
                NotificationCenter.default.post(name: .pnPermissionsDidChange, object: nil)
            }
        }
    }

    func isPNAuthorizationNotDetermined() -> Bool {
        return UserDefaults.standard.integer(forKey: "pnPermissionsState") == 0
    }

    func checkAuthorization() -> Bool {
        let state = UserDefaults.standard.integer(forKey: "pnPermissionsState")
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            var newState: Int
            if settings.authorizationStatus == .authorized {
                newState = 1
            } else if settings.authorizationStatus == .notDetermined {
                newState = 0
            } else {
                // includes provisional since we are not using it
                newState = -1
            }
            if newState != UserDefaults.standard.integer(forKey: "pnPermissionsState") {
                UserDefaults.standard.set(newState, forKey: "pnPermissionsState")
                NotificationCenter.default.post(name: .pnPermissionsDidChange, object: nil)
            }
        }
        return state == 1
    }

    func getPushNotifSetting(completionHandler: @escaping (Int) -> Void) {
        DispatchQueue.main.async {
            UNUserNotificationCenter.current().getNotificationSettings { (notificationSettings) in
                switch notificationSettings.authorizationStatus {
                case .authorized:
                    completionHandler(10)
                case .denied:
                    completionHandler(4)
                case .notDetermined:
                    completionHandler(0)
                case .provisional:
                    completionHandler(2)
                @unknown default:
                    completionHandler(3)
                }
            }
        }
    }

    func setupBluetoothPNStatusCallback() {
        let btStatusMagicNumber = Int.random(in: 0 ... PushNotificationConstants.btStatusPushNotifContents.count - 1)

        BluetraceManager.shared.bluetoothDidUpdateStateCallback = { [unowned self] () -> Void in
            if BluetraceManager.shared.isBluetoothOn() {
                // reset
                UserDefaults.standard.set(false, forKey: "sentBluetoothStatusNotif")
            }
            if OnboardingManager.shared.allowedBluetoothPermissions && !BluetraceManager.shared.isBluetoothOn() && !BluetraceManager.shared.isBluetoothResettingOrUnknown() {
                if !UserDefaults.standard.bool(forKey: "sentBluetoothStatusNotif") {
                    UserDefaults.standard.set(true, forKey: "sentBluetoothStatusNotif")
                    LogMessage.create(type: .Info, title: #function, details: "PN triggered - Bluetooth State \(String(UserDefaults.standard.integer(forKey: "bluetoothState")))", collectable: true, timestamp: Date())
                        self.triggerIntervalLocalPushNotifications(pnContent: PushNotificationConstants.btStatusPushNotifContents[btStatusMagicNumber], identifier: "bluetoothStatusNotifId")
                }
            }
        }
    }

    func triggerIntervalLocalPushNotifications(pnContent: [String: String], identifier: String) {
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = pnContent["contentTitle"]!
        content.body = pnContent["contentBody"]!

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request)
    }
}

@available(iOS 10, *)
extension BlueTraceLocalNotifications: UNUserNotificationCenterDelegate {

    // when user receives the notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo as! [String: Any]
        let gcmMessageIDKey = "gcm.message_id"
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            LogMessage.create(type: .Info, title: #function, details: "Message ID: \(messageID)", debugMessage: "Message ID: \(messageID)")
        }
        completionHandler([.alert, .badge, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        LogMessage.create(type: .Info, title: "\(#function)", details: "identifier: \(response.notification.request.identifier)", collectable: true)
        if response.notification.request.identifier == "bluetoothStatusNotifId" && !BluetraceManager.shared.isBluetoothAuthorized() {
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
        }
        completionHandler()
    }
}
