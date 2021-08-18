//
//  AppDelegate.swift
//  OpenTraceTogether

import UIKit
import BackgroundTasks
import CoreData
import Firebase
import FirebaseAuth
import FirebaseRemoteConfig
import FirebaseAnalytics
import CoreMotion
import SupportSDK
import ZendeskCoreSDK
import AVFoundation
import AVKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var player: AVPlayer?
    var audioItem: AVPlayerItem?
    var reachability: Reachability?
    var launchUrl: URL?
    var userActivityType: String?
    var shortcutItemType: String?
    var batteryState: UIDevice.BatteryState { UIDevice.current.batteryState }
    var batteryLevel: Float { UIDevice.current.batteryLevel }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UITabBarItem.appearance().applyAppAppearance()
        UIDevice.current.isBatteryMonitoringEnabled = true
        NotificationCenter.default.addObserver(self, selector: #selector(batteryStateDidChange), name: UIDevice.batteryStateDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(batteryLevelDidChange), name: UIDevice.batteryLevelDidChangeNotification, object: nil)

        do {
            try self.reachability = Reachability()
            try reachability?.startNotifier()
        } catch {
            print( "ERROR: Could not start reachability notifier." )
            LogMessage.create(type: .Error, title: #function, details: "ERROR: Could not start reachability notifier.")
        }

        Services.database = DatabaseService()
        Services.encounter = EncounterService()

        LogMessage.removeCollectableLogsMoreThan14DaysAgo()
        LogMessage.logAppStart(launchOptions)

        // MARK: Registering Launch Handlers for Tasks
        if #available(iOS 13.0, *) {
            BGTaskScheduler.shared.register(forTaskWithIdentifier: "sg.gov.tracetogether.get_temp_ids_from_server", using: nil) { task in
                // Downcast the parameter to an app refresh task as this identifier is used for a refresh request.
                self.handleAppRefresh(task: task as! BGAppRefreshTask)
            }
            BGTaskScheduler.shared.register(forTaskWithIdentifier: "sg.gov.tracetogether.get_temp_ids_from_server_bg_processing", using: nil) { task in
                // Downcast the parameter to a processing task as this identifier is used for a processing request.
                self.handleBackgroundProcessing(task: task as! BGProcessingTask)
            }
        } else {
            // Fallback on earlier versions
        }

        // Initialize Zendesk SupportSDK
        Zendesk.initialize(appId: config.appId, clientId: config.clientId, zendeskUrl: config.zendeskUrl)

        let identity = Identity.createAnonymous()
        Zendesk.instance?.setIdentity(identity)

        Support.initialize(withZendesk: Zendesk.instance)

        // Override point for customization after application launch.
        FirebaseApp.configure()

        UIApplication.shared.isIdleTimerDisabled = true

        BlueTraceLocalNotifications.shared.initialConfiguration()

        RemoteConfigManager.shared.addObserver(self, selector: #selector(remoteConfigDidUpdated))
        navigateToCorrectPage()

        DispatchQueue.main.async {
            FirebaseCloudMessaging.shared.setup()
            application.registerForRemoteNotifications()
        }

        if isBelowMandatoryVersion() {
            // do not allow quick action to execute
            return false
        }

        return true
    }

    func navigateToCorrectPage() {
        let navController = self.window!.rootViewController! as! UINavigationController
        let vc =  OnboardingManager.shared.returnCurrentViewController()
        navController.setViewControllers([vc], animated: false)
    }

    @objc func batteryStateDidChange(_ notification: Notification) {
        //Log battery state to troubleshoot app performance and to see if it is affecting the bluetooth stack
        switch batteryState {
        case .unplugged:
            LogMessage.create(type: .Info, title: "BatteryStateDidChange", details: ["batteryState": "unplugged"], collectable: true)
        case .charging:
            LogMessage.create(type: .Info, title: "BatteryStateDidChange", details: ["batteryState": "charging"], collectable: true)
        case .full:
            LogMessage.create(type: .Info, title: "BatteryStateDidChange", details: ["batteryState": "full"], collectable: true)
        default:
            LogMessage.create(type: .Info, title: "BatteryStateDidChange", details: ["batteryState": "unknown"], collectable: true)
        }
    }

    @objc func batteryLevelDidChange(_ notification: Notification) {
        if batteryLevel < 15.0 {
            //Log battery state to see if low battery levels are affecting the app performance and the bluetooth stack
            LogMessage.create(type: .Info, title: "batteryLevelDidChange", details: ["batteryLevel": "\(batteryLevel)"], collectable: true)
        }
    }

    // MARK: - Scheduling Tasks

    @available(iOS 13.0, *)
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "sg.gov.tracetogether.get_temp_ids_from_server")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 6 * 60 * 60) // Fetch no earlier than 6 hours from now

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
            LogMessage.create(type: .Error, title: #function, details: "Could not schedule app refresh: \(error)")
        }

    }

    @available(iOS 13.0, *)
    func scheduleBGProcessingTask() {
        let lastBatchReceivedDate = TempIDManager.shared.getLastBatchReceivedDate() ?? .distantPast

        let now = Date()
        let oneDay = TimeInterval(24 * 60 * 60)

        // Fetch the tempID at most once per day.
        guard now > (lastBatchReceivedDate + oneDay) else { return }

        let request = BGProcessingTaskRequest(identifier: "sg.gov.tracetogether.get_temp_ids_from_server_bg_processing")
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule BGProcessingTask error: \(error)")
            LogMessage.create(type: .Error, title: #function, details: "Could not schedule BGProcessingTask: \(error)")
        }
    }

    // MARK: - Handling Launch for Tasks

    // Fetch the latest feed entries from server.
    @available(iOS 13.0, *)
    func handleAppRefresh(task: BGAppRefreshTask) {
        LogMessage.create(type: .Info, title: "BGAppRefreshTask", collectable: true)
        scheduleAppRefresh()

        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1

        let operation = BlockOperation {
            LogMessage.create(type: .Info, title: "BGAppRefreshTask", details: "operationStarted", collectable: true)
            self.checkBluetoothAndUpdateTempID()
            BlueTraceLocalNotifications.shared.getPushNotifSetting { (notifSettingEnum) in
                DispatchQueue.main.async {
                    FirebaseAPIs.sendHeartbeatEvent(notifSetting: notifSettingEnum)
                }
            }
        }

        task.expirationHandler = {
            LogMessage.create(type: .Info, title: "BGAppRefreshTask", details: "operationExpired", collectable: true)
            queue.cancelAllOperations()
        }

        operation.completionBlock = {
            LogMessage.create(type: .Info, title: "BGAppRefreshTask", details: ["cancelled": "\(operation.isCancelled)"], collectable: true)
            task.setTaskCompleted(success: !operation.isCancelled)
        }

        queue.addOperation(operation)
    }

    // Delete feed entries older than one day.
    @available(iOS 13.0, *)
    func handleBackgroundProcessing(task: BGProcessingTask) {
        LogMessage.create(type: .Info, title: "BGProcessingTask", collectable: true)
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1

        let operation = BlockOperation {
            LogMessage.create(type: .Info, title: "BGProcessingTask", details: "operationStarted", collectable: true)
            self.checkBluetoothAndUpdateTempID()
            BlueTraceLocalNotifications.shared.getPushNotifSetting { (notifSettingEnum) in
                DispatchQueue.main.async {
                    FirebaseAPIs.sendHeartbeatEvent(notifSetting: notifSettingEnum)
                }
            }
        }

        task.expirationHandler = {
            LogMessage.create(type: .Info, title: "BGProcessingTask", details: "operationExpired", collectable: true)
            queue.cancelAllOperations()
        }

        operation.completionBlock = {
            LogMessage.create(type: .Info, title: "BGProcessingTask", details: ["cancelled": "\(operation.isCancelled)"], collectable: true)
            task.setTaskCompleted(success: !operation.isCancelled)
        }

        queue.addOperation(operation)
    }

    func checkBluetoothAndUpdateTempID() {
        let bluetoothAuthorised = BluetraceManager.shared.isBluetoothAuthorized()
        if OnboardingManager.shared.allowedBluetoothPermissions && bluetoothAuthorised {
            TempIDManager.shared.updateTempIDIfNecessary()
        } else {
            print("No need to update.")
        }
    }

    // MARK: - Application Lifecycles

    func applicationDidBecomeActive(_ application: UIApplication) {
        LogMessage.create(type: .Info, title: "Application", details: "didBecomeActive")

        // Remove blurView if transition was incomplete from SE Barcode View
        window?.viewWithTag(100)?.removeFromSuperview()

        //the below is only needed in DidBecomeActive because DidBecomeActive is also called when the application launches
        // Also checks if user is onboarded
        checkBluetoothAndUpdateTempID()
        enforceVersionNumber(enforceRecommended: false)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        LogMessage.create(type: .Info, title: "Application", details: "willResignActive")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        LogMessage.create(type: .Info, title: "Application", details: "didEnterBackground", collectable: true)
        if #available(iOS 13.0, *) {
            scheduleAppRefresh()
            scheduleBGProcessingTask()
        } else {
            // Do nothing
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        LogMessage.create(type: .Info, title: "Application", details: "willEnterForeground", collectable: true)
        // Remove blurView if transition was incomplete from SE Barcode View
        window?.viewWithTag(100)?.removeFromSuperview()
        Services.encounter.removeData25DaysOld()
        SafeEntryUtils.removeSafeEntryDataOlderThan15Days()

        if HistoryExposureController.exposuresHaveExpired() {
            UserDefaults.standard.removeObject(forKey: "exposureModels")
            HistoryExposureController.shared.exposures = []
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        LogMessage.create(type: .Info, title: "Application", details: "willTerminate", collectable: true)
    }

    // MARK: - Remote Notification
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        handleRemoteNotification(application, didReceiveRemoteNotification: userInfo)
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        handleRemoteNotification(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
    }

    func handleRemoteNotification(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                                  fetchCompletionHandler completionHandler: ((UIBackgroundFetchResult) -> Void)? = nil) {
        // Print full message.
        print(userInfo)
        LogMessage.create(type: .Info, title: "\(#function)", details: ["userInfo": String(describing: userInfo)], collectable: true)

        let firebaseAuthKey = "com.google.firebase.auth"
        if let firebaseDummyNotif = userInfo[firebaseAuthKey] {
            let debugDetails = "Do not send heartbeat - this is first time auth \(firebaseDummyNotif)"
            LogMessage.create(type: .Info, title: #function, details: debugDetails, debugMessage: debugDetails)
            return
        }

        // With swizzling disabled you must let Messaging know about the message, for Analytics
        //        Messaging.messaging().appDidReceiveMessage(userInfo)
        let gcmMessageIDKey = "gcm.message_id"
        let purposeKey = "purpose"
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            let debugDetails = "Normal Message ID: \(messageID)"
            LogMessage.create(type: .Info, title: #function, details: debugDetails, debugMessage: debugDetails)

            checkBluetoothAndUpdateTempID()
            if let purpose = userInfo[purposeKey] {
                if purpose as! String == "heartbeat" {
                    BlueTraceLocalNotifications.shared.getPushNotifSetting { (notifSettingEnum) in
                        LogMessage.create(type: .Info, title: "\(#function)", details: ["notifSettingEnum": String(describing: notifSettingEnum)], collectable: true)
                        DispatchQueue.main.async {
                            FirebaseAPIs.sendHeartbeatEvent(notifSetting: notifSettingEnum, onComplete: { (_) -> Void in
                                completionHandler?(UIBackgroundFetchResult.newData)
                            })
                        }
                    }
                }
            }
        }

    }

    func presentUpdateAlert(isMandatory: Bool) {
        let updateAction = UIAlertAction(title: "Update", style: .default, handler: { _ in
            if let url = URL(string: "itms-apps://itunes.apple.com/app/id1498276074"), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        })
        let cancelAction = UIAlertAction(title: NSLocalizedString("RemindMeAgain", comment: "Remind me again"), style: .cancel)

        if isMandatory {
            let alert = UIAlertController(title: NSLocalizedString("UpdateAppNowTitle", comment: "Update app now"), message: NSLocalizedString("UpdateAppNowMessage", comment: "We’ve made important changes, and you need to update the app to continue using TraceTogether."), preferredStyle: .alert)
            alert.addAction(updateAction)
            alert.preferredAction = updateAction
            self.window?.rootViewController?.present(alert, animated: true)
        } else {
            let alert = UIAlertController(title: NSLocalizedString("NewVersionAvailableTitle", comment: "New version available"), message: NSLocalizedString("NewVersionAvailableMessage", comment: "We’ve improved TraceTogether to serve you better! Update it now."), preferredStyle: .alert)
            alert.addAction(updateAction)
            alert.addAction(cancelAction)
            alert.preferredAction = updateAction
            self.window?.rootViewController?.present(alert, animated: true)
        }
    }

    func isBelowMandatoryVersion() -> Bool {
        let mandatoryMinVersion = RemoteConfig.remoteConfig()[RemoteConfigKeys.mandatoryMinimumVersionIOS].stringValue!
        return VersionNumberHelper.getCurrentVersion().isVersionLowerThan(mandatoryMinVersion)
    }

    func isBelowRecommendedVersion() -> Bool {
        let recommendedMinVersion = RemoteConfig.remoteConfig()[RemoteConfigKeys.recommendedMinimumVersionIOS].stringValue!
        return VersionNumberHelper.getCurrentVersion().isVersionLowerThan(recommendedMinVersion)
    }

    func enforceVersionNumber(enforceRecommended: Bool) {
        if isBelowMandatoryVersion() {
            presentUpdateAlert(isMandatory: true)
        } else if enforceRecommended && isBelowRecommendedVersion() {
            presentUpdateAlert(isMandatory: false)
        }
    }

    @objc func remoteConfigDidUpdated() {
        enforceVersionNumber(enforceRecommended: true)
    }

    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        shortcutItemType = shortcutItem.type
        completionHandler(true)
    }

    func application(_ application: UIApplication, shouldAllowExtensionPointIdentifier extensionPointIdentifier: UIApplication.ExtensionPointIdentifier) -> Bool {
        return extensionPointIdentifier != UIApplication.ExtensionPointIdentifier.keyboard
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        launchUrl = url
        return true
    }

    func application(_ application: UIApplication, willContinueUserActivityWithType userActivityType: String) -> Bool {
        self.userActivityType = userActivityType
        return true
    }
}
