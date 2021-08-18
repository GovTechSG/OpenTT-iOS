//
//  FirebaseCloudMessaging.swift
//  OpenTraceTogether

import Firebase
import FirebaseMessaging
import UserNotifications
import UIKit

class FirebaseCloudMessaging: NSObject {

    static let shared = FirebaseCloudMessaging()
    let fcmTokenKey = "FCM_TOKEN"
    let gcmMessageIDKey = "gcm.message_id"

    func setup() {
        Messaging.messaging().delegate = self
    }
}

extension FirebaseCloudMessaging: MessagingDelegate, UNUserNotificationCenterDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        let existingFCMtoken = UserDefaults.standard.string(forKey: FirebaseCloudMessaging.shared.fcmTokenKey) ?? "UnknownFCMToken"
        if fcmToken == existingFCMtoken {
            return
        }
        UserDefaults.standard.set(fcmToken, forKey: fcmTokenKey)

        let hasCurrentUser = FirebaseAPIs.currentUserId != nil
        if hasCurrentUser == false {
            return
        }

        let ttId = UserDefaults.standard.string(forKey: "ttId") ?? "Unknown"
        if ttId == "Unknown" {
            LogMessage.create(type: .Info, title: #function, details: "Unknown ttid", collectable: true)
            return
        }

        FirebaseAPIs.registerFCMToken { (success) in
            let debugMessage = (success != nil) ? "Token registered from token refresh" : "Token failed to register"
            LogMessage.create(type: .Info, title: #function, details: debugMessage, collectable: true, debugMessage: debugMessage)
            // Subscribe to HeartBeat topic
            DispatchQueue.main.async {
                Messaging.messaging().subscribe(toTopic: "heartbeat") { error in
                    if let err = error {
                        LogMessage.create(type: .Error, title: #function, details: err.localizedDescription, collectable: true)
                        print(err)
                    }
                  print("Subscribed to heartbeat topic after token update!")
                LogMessage.create(type: .Info, title: #function, details: "Subscribed to heartbeat topic after token update!", collectable: true)
                }
            }
        }

        let dataDict: [String: String] = ["token": fcmToken]
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)

    }

}
