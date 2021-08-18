//
//  FirebaseAPIs.swift
//  OpenTraceTogether

import Foundation
import FirebaseFunctions
import FirebaseAuth

struct FirebaseAPIs {
    static var functions = Functions.functions(region: "XX")
    static var id_holder = ""
    static var postal_code_holder = ""

    static func verify(phoneNumber: String, _ onComplete: VerificationResultCallback?) {
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil, completion: onComplete)
    }

    static func signIn(withVerificationID verificationID: String, otp: String, _ onComplete: @escaping (Error?) -> Void) {
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: otp)
        Auth.auth().signIn(with: credential) { onComplete($1) }
    }

    static var currentUserId: String? {
        #if TEST
        return UserDefaults.standard.string(forKey: "mock_firebaseUid")
        #else
        return Auth.auth().currentUser?.uid
        #endif
    }

    static func getHandshakePin(_ onComplete: @escaping (String?) -> Void) {
        #if TEST
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            onComplete("MOCK_PIN")
        }
        #else
        LogMessage.create(type: .Info, title: #function, details: "Started...")
        functions.httpsCallable("getHandshakePin").call { (resp, error) in
            guard error == nil else {
                LogMessage.create(type: .Error, title: #function, details: "Handshake failed: \(error?.localizedDescription ?? "Missing error object")")
                FirebaseAPIs.handleError(error: error!, title: #function) {_ in
                    onComplete(nil)
                }
                return
            }
            guard let pin = (resp?.data as? [String: Any])?["pin"] as? String else {
                onComplete(nil)
                return
            }
            onComplete(pin)
        }
        #endif
    }

    static func getPassportStatus(_ onComplete: @escaping (Bool?, Error?) -> Void) {
        guard let ttId = UserDefaults.standard.string(forKey: "ttId") else {
            LogMessage.create(type: .Error, title: #function, details: "ttid is missing")
            onComplete(nil, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "ttid is missing"]))
            return
        }
        let dataDict = [ "ttId": ttId]
        functions.httpsCallable("getPassportStatus").call(dataDict) { (resp, error) in
            guard error == nil else {
                if let error = error as NSError? {
                    if error.domain == FunctionsErrorDomain {
                        let code = FunctionsErrorCode(rawValue: error.code)
                        let message = error.localizedDescription
                        let details = error.userInfo[FunctionsErrorDetailsKey]
                        let debugMessage = "Cloud function error. Code: \(String(describing: code)), Message: \(message), Details: \(String(describing: details))"
                        LogMessage.create(type: .Error, title: #function, details: debugMessage, collectable: true, debugMessage: debugMessage)
                        onComplete(nil, error)
                        return
                    }
                } else {
                    LogMessage.create(type: .Error, title: #function, details: "Cloud function error. Unable to convert error to NSError.\(error!)", collectable: true)
                }
                onComplete(nil, error)
                return
            }
            guard let status = (resp?.data as? [String: Any])?["status"] as? String, status == "SUCCESS" else {
                onComplete(nil, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "API status failure"]))
                return
            }
            guard let message = (resp?.data as? [String: Any])?["message"] as? Bool else {
                onComplete(nil, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "message not available"]))
                return
            }
            LogMessage.create(type: .Error, title: #function, details: "API Success - Passport valid \(message)")
            onComplete(message, nil)
        }
    }

    enum UpdateUserInfoResultType {
        case shouldStartOver
        case validationFailed
        case commonError(Error)
        case successWithPermissionTurnedOn
        case success
        case needPermission
        case useDifferentProfile
        case rateLimitError
    }

    static func callAPI(_ name: String, data: Any? = nil, completion: @escaping (Any?, Error?) -> Void) {
        functions.httpsCallable(name).call(data) { completion($0?.data, $1) }
    }

    static func updateUserInfo(formFieldsDict: [String: Any], idType: String, _ onComplete: @escaping (UpdateUserInfoResultType) -> Void) {
        let model = DeviceIdentifier.modelName
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        //Required additional fields
        var dataDict = formFieldsDict
        dataDict["appVersion"] = appVersion
        dataDict["model"] = model
        dataDict["idType"] = idType
        dataDict["declaration"] = true

        callAPI("updateUserInfo", data: dataDict) { (data, error) in

            if let error = error as NSError? {
                let code = FunctionsErrorCode(rawValue: error.code)
                let message = error.localizedDescription
                let details = error.userInfo[FunctionsErrorDetailsKey]
                let debugMessage = "Cloud function error. Code: \(String(describing: code)), Message: \(message), Details: \(String(describing: details))"
                LogMessage.create(type: .Error, title: "updateUserInfo", details: message, collectable: true, debugMessage: debugMessage)
                if code == .some(.resourceExhausted) {
                    return onComplete(.rateLimitError)
                } else {
                    return onComplete(.commonError(error))
                }
            }

            var passportValid = false

            if dataDict["idType"] as? String == "passport" {
                let passportStatus = (data as? [String: Any])?["passportStatus"] as? String
                switch passportStatus {
                case "MATCH":
                    passportValid = true
                case "MATCH - SGR":
                    return onComplete(.useDifferentProfile)
                case "NO MATCH":
                    LogMessage.create(type: .Error, title: #function, details: "No Match found for the Passport")
                    return onComplete(.validationFailed)
                default:
                    LogMessage.create(type: .Error, title: #function, details: "No passport status returned")
                    return onComplete(.commonError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No passport status returned"])))
                }
            }

            guard let ttId = (data as? [String: Any])?["ttId"] as? String else {
                LogMessage.create(type: .Error, title: "updateUserInfo", details: "ttId missing")
                return onComplete(.validationFailed)
            }

            for (key, value) in formFieldsDict {
                if (key == "id") {
                    do {
                        let credentials = SecureStore.Credentials(username: "id", password: value as! String)
                        try SecureStore.addOrUpdateCredentials(credentials, service: "nricService" )
                        _ = try SecureStore.readCredentials(service: "nricService", accountName: "id").password
                    } catch {
                        LogMessage.create(type: .Error, title: "updateUserInfo", details: error.localizedDescription)
                        return onComplete(.shouldStartOver)
                    }
                } else {
                    let userProfileKey = "userprofile_" + key
                    UserDefaults.standard.set(value, forKey: userProfileKey)
                }
            }
            UserDefaults.standard.set(idType, forKey: "idType")
            UserDefaults.standard.set(ttId, forKey: "ttId")
            if passportValid {
                UserDefaults.standard.setValue(true, forKey: "PassportVerificationStatus")
            }
            dateOfRegistration = Date()
            OnboardingManager.shared.hasConsented = true
            VersionNumberHelper.appVersionOnRegistration = VersionNumberHelper.getCurrentVersion()
            TempIDManager.shared.updateTempIDIfNecessary()
            if BluetraceManager.shared.isBluetoothAuthorizationNotDetermined() || BlueTraceLocalNotifications.shared.isPNAuthorizationNotDetermined() || OnboardingManager.shared.allowedBluetoothPermissions == false {
                return onComplete(.needPermission)
            }
            if PermissionsUtils.isAllPermissionsAuthorized() {
                return onComplete(.successWithPermissionTurnedOn)
            }
            return onComplete(.success)
        }
    }

    static func registerFCMToken(_ onComplete: @escaping (Bool?) -> Void) {
        let ttId = UserDefaults.standard.string(forKey: "ttId") ?? "Unknown"
        if ttId == "Unknown" {
            print("ttId Unknown - do not registerFCMToken")
            onComplete(nil)
            return
        }
        let FCMtoken = UserDefaults.standard.string(forKey: FirebaseCloudMessaging.shared.fcmTokenKey) ?? "UnknownFCMToken"
        let deviceiOSString = "ios"
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as Any
        let dataDict = ["appVersion": appVersion, "token": FCMtoken, "deviceOS": deviceiOSString, "ttId": ttId] as [String: Any]

        functions.httpsCallable("registerFCMToken").call(dataDict) { (_, error) in
            guard error == nil else {
                FirebaseAPIs.handleError(error: error!, title: #function) {_ in
                    onComplete(nil)
                }
                return
            }
            onComplete(true)
        }
    }

    static func sendHeartbeatEvent(notifSetting: Int, onComplete: ((Bool) -> Void)? = nil) {
        let data = ["platform": "ios",
                    "appVersion": (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "Unknown",
                    "bluetoothStateSettings": BluetraceManager.shared.getBluetoothStateSetting(),
                    "ttId": UserDefaults.standard.string(forKey: "ttId") ?? "Unknown",
                    "bluetoothSettings": BluetraceManager.shared.getBluetoothSetting(),
                    "pushNotificationSettings": notifSetting,
                    "prevDayBTEncounterCount": Encounter.getPrevDayCount(),
                    "lastBTEncounterTimestamp": Encounter.getMostRecentEncounterTimestamp(),
                    "timestamp": Int64(NSDate().timeIntervalSince1970)
            ] as [String: Any]

        functions.httpsCallable("sendHeartbeat").call(data) { (resp, error) in
            guard error == nil else {
                FirebaseAPIs.handleError(error: error!, title: #function) {_ in
                    onComplete?(false)
                }
                return
            }
            LogMessage.create(type: .Info, title: #function, details: "Cloud function response - \(resp!)", debugMessage: "Cloud function response - \(resp!)")
            onComplete?(true)
        }
    }

    static func getTempIDsV3(onComplete: ((Error?, (tempIDs: [[String: Any]], shortTempIDs: [[String: Any]], refreshDate: Date)?) -> Void)?) {
        let ttId = UserDefaults.standard.string(forKey: "ttId") ?? "Unknown"
        if ttId == "Unknown" {
            LogMessage.create(type: .Error, title: #function, details: "Unknown TTID")
            onComplete?(nil, nil)
            return
        }

        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let model = DeviceIdentifier.modelName
        let osVersion = UIDevice.current.systemVersion
        let deviceiOSString = "ios"
        let btLiteVersion = BluetraceConfig.BtLiteVersion

        let data = [ "ttId": ttId, "appVersion": appVersion, "model": model, "os": deviceiOSString, "osVersion": osVersion, "btLiteVersion": btLiteVersion]

        LogMessage.create(type: LogMessage.LogType.Info, title: "Fetch new batch of V3TempIDs")
        functions.httpsCallable("getTempIDsV3").call(data) { (result, error) in
            // Handle error
            guard error == nil else {
                FirebaseAPIs.handleError(error: error!, title: "\(#function) Error fetching tempIDs") {_ in
                    onComplete?(error, nil)
                }
                return
            }

            // Parse the results as a sanity check
            guard let tempIdsInBase64 = (result?.data as? [String: Any])?["tempIDs"] as? [[String: Any]],
                  let shortTempIdsInBase64 = (result?.data as? [String: Any])?["shortTempIDs"] as? [[String: Any]],
                  let batchRefreshDate = (result?.data as? [String: Any])?["refreshTime"] as? Double else {
                let debugMessage = "Unable to parse tempId or refreshTime from Firebase. result of function call: \(String(describing: result))"
                LogMessage.create(type: .Error, title: #function, details: "Unable to parse tempId or refreshTime from Firebase.", debugMessage: debugMessage)
                onComplete?(NSError(domain: "BM", code: 9999, userInfo: nil), nil)
                return
            }
            onComplete?(nil, (tempIdsInBase64, shortTempIdsInBase64, Date(timeIntervalSince1970: batchRefreshDate)))
        }
    }

    static func handleError(error: Error, title: String, onComplete: (_ message: String) -> Void) {
        if let error = error as NSError? {
            if error.domain == FunctionsErrorDomain {
                let code = FunctionsErrorCode(rawValue: error.code)
                let message = error.localizedDescription
                let details = error.userInfo[FunctionsErrorDetailsKey]
                let debugDetails = "Cloud function error. Code: \(String(describing: code)), Message: \(message), Details: \(String(describing: details))"
                LogMessage.create(type: .Error, title: title, details: debugDetails, debugMessage: debugDetails)
                onComplete(debugDetails)
            }
        } else {
            let debugDetails = "Cloud function error, unable to convert error to NSError.\(error)"
            LogMessage.create(type: .Error, title: title, details: debugDetails, debugMessage: debugDetails)
            onComplete("error is not NSError")
        }
    }
}
