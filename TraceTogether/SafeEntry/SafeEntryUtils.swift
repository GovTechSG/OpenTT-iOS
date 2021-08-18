//
//  SafeEntryUtils.swift
//  OpenTraceTogether

import Foundation
import UIKit
import FirebaseFunctions

enum SafeEntryActionType: String {
    case checkin
    case checkout
}

struct SafeEntryConfig {
    static let TTLDays = -16
    static let SEHistoryDays = -15
    static let TTLHours = -24 // 1 day
    static let ExposureTTL = 6 * 60 * 60
    static let LogHistoryDays = -14
}

struct SafeEntryUtils {

    static func dataDictForSafeEntryAPI(ttId: String) -> [String: Any] {
        let deviceiOSString = "ios"
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as Any
        let model = DeviceIdentifier.modelName
        let osVersion = UIDevice.current.systemVersion
        let dataDict = [ "ttId": ttId, "appVersion": appVersion, "model": model, "os": deviceiOSString, "osVersion": osVersion] as [String: Any]
        return dataDict
    }

    static func displayErrorAlertController(err: Error?, vc: UIViewController, customErrMsgTitle: String) {
        let errMessage = err != nil ? err!.localizedDescription : "Invalid status received!"
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        let alert = UIAlertController(title: customErrMsgTitle, message: errMessage, preferredStyle: .alert)
        alert.addAction(cancelAction)
        alert.preferredAction = cancelAction
        vc.present(alert, animated: true)
        return
    }

    static func displayErrorAlertController(err: Error?, vc: UIViewController, customErrMsgTitle: String, withCustomCancelAction cancelAction: UIAlertAction) {
        let errMessage = err != nil ? err!.localizedDescription : "Invalid status received!"
        let alert = UIAlertController(title: customErrMsgTitle, message: errMessage, preferredStyle: .alert)
        alert.addAction(cancelAction)
        alert.preferredAction = cancelAction
        vc.present(alert, animated: true)
        return
    }

    static func displayErrorAlertController(vc: UIViewController, customErrMsgTitle: String, customErrMsg: String, withCustomCancelAction cancelAction: UIAlertAction) {
        let alert = UIAlertController(title: customErrMsgTitle, message: customErrMsg, preferredStyle: .alert)
        alert.addAction(cancelAction)
        alert.preferredAction = cancelAction
        vc.present(alert, animated: true)
        return
    }

    static func displayErrorAlertController(vc: UIViewController, customErrMsgTitle: String, customErrMsg: String) {
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        let alert = UIAlertController(title: customErrMsgTitle, message: customErrMsg, preferredStyle: .alert)
        alert.addAction(cancelAction)
        alert.preferredAction = cancelAction
        vc.present(alert, animated: true)
        return
    }

    static func displayErrorAlertNoInternetController(vc: UIViewController, customErrMsgTitle: String, withCustomRetryAction retryAction: UIAlertAction, cancelAction: UIAlertAction? = nil) {
        let alert = UIAlertController(title: customErrMsgTitle, message: NSLocalizedString("NetworkIssue", comment: "There seems to be a network issue. Check your connection and try again."), preferredStyle: .alert)
        alert.addAction(retryAction)
        if let cancelAction = cancelAction {
            alert.addAction(cancelAction)
        } else {
            let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel)
            alert.addAction(cancelAction)
        }
        alert.preferredAction = retryAction
        vc.present(alert, animated: true)
    }

    static func getDateStringForCheckInOutViewDisplay(_ date: Date) -> String {
        let dateformatter = DateFormatter()
        dateformatter.locale = Locale(identifier: "en_SG")
        dateformatter.dateFormat = "dd MMM yyyy"
        return dateformatter.string(from: date).uppercased()
    }

    static func getTimeStringForCheckInOutViewDisplay(_ date: Date) -> String {
        let timeformatter = DateFormatter()
        timeformatter.locale = Locale(identifier: "en_SG")
        timeformatter.dateFormat = "h:mm a"
        return timeformatter.string(from: date).uppercased()
    }

    static func convertRemoteTimestampToDateObject(dateString: String?) -> Date? {
        guard let validDateString = dateString else {
            return nil
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MMM-yyyy'T'HH:mm:ssZ"
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.locale = Locale(identifier: "en_SG")

        guard let date = dateFormatter.date(from: validDateString) else {
            assert(false, "no date from string")
            return nil
        }

        dateFormatter.dateFormat = "yyyy MMM EEEE HH:mm"
        dateFormatter.timeZone = TimeZone.current
        let timeStamp = dateFormatter.string(from: date)

        return date
    }

    static func removeSafeEntryDataOlderThan15Days() {
        LogMessage.create(type: .Info, title: #function, details: "Removing 15 days old data from device!", debugMessage: "Removing 15 days old data from device!")

        // For e.g. 19th of Jan, we get reverseCutOffDate of 3rd Jan
        let reverseCutOffDate: Date? = Calendar.appCalendar.date(byAdding: .day, value: SafeEntryConfig.TTLDays, to: Date())

        if let validDate = reverseCutOffDate {
            let predicateForDel = NSPredicate(format: "checkInDate < %@", validDate as NSDate)
            Services.database.delete(SafeEntrySession.self, predicate: predicateForDel)
        }
    }

    static func formatSETenantVenueDisplay(_ tenantName: String?, _ venueName: String?) -> String {
        guard let validVenueName = venueName?.uppercased() else { return "" }

        if let validTenantName = tenantName?.uppercased(), validTenantName != "" {
            return "\(validTenantName) (\(validVenueName))"
        } else {
            return validVenueName
        }
    }

    static func isUserAllowedToSafeEntry() -> Bool {
        if isPassportUser() && UserDefaults.standard.bool(forKey: "PassportVerificationStatus") == false {
            return false
        }
        return true
    }

    static func isPassportUser() -> Bool {
        if let idType = UserDefaults.standard.string(forKey: "idType") {
            let profileType = NricFinChecker.checkIdType(idType: idType)
            return profileType == ProfileType.Visitor
        }
        return false
    }

    static func setupSEQuickAction() {
        if isUserAllowedToSafeEntry() {
            guard let bundleIdentifier = Bundle.main.bundleIdentifier else { return }
            let safeEntryShortcutType = bundleIdentifier + ".safeEntry"
            let safeEntryShortCutIcon = UIApplicationShortcutIcon(templateImageName: "SEcheckInFor_QuickAction")
            let safeEntryShortCutItem = UIApplicationShortcutItem(type: safeEntryShortcutType, localizedTitle: "SafeEntry Check In", localizedSubtitle: nil, icon: safeEntryShortCutIcon, userInfo: nil)
            UIApplication.shared.shortcutItems = [safeEntryShortCutItem]
        } else {
            UIApplication.shared.shortcutItems = []
        }
    }

    static func clearQuickActions() {
        UIApplication.shared.shortcutItems = []
    }

}
