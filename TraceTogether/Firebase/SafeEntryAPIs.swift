//
//  SafeEntryAPIs.swift
//  OpenTraceTogether

import Foundation
import FirebaseFunctions

struct SafeEntryAPIs {

    static var functions = Functions.functions(region: "XX")

    static private func httpsCallable<T>(_ name: String, idKey: String? = nil, params: [String: Any]? = nil, dataKeys: [String]? = nil, onComplete: @escaping (T?, Error?) -> Void, otherResponseHandler: ((T) -> String?)? = nil) {
        let logError = { (details: String) in
            LogMessage.create(type: .Error, title: "\(name)API", details: details, collectable: true)
        }

        //check for ttid
        guard let ttId = UserDefaults.standard.string(forKey: "ttId"), !ttId.isEmpty else {
            logError("ttId Unknown")
            onComplete(nil, nil)
            return
        }
        var dataDict = SafeEntryUtils.dataDictForSafeEntryAPI(ttId: ttId)

        //check for id
        if let idKey = idKey {
            do {
                let userIdValue = try SecureStore.readCredentials(service: "nricService", accountName: "id").password
                dataDict[idKey] = userIdValue
            } catch {
                logError(error.localizedDescription)
                onComplete(nil, nil)
                return
            }
        }

        //append additional params
        params?.forEach { dataDict[$0.key] = $0.value }

        FirebaseAPIs.callAPI(name, data: dataDict) { (response, error) in
            //check error
            guard error == nil else {
                if let error = error as NSError?, error.domain == FunctionsErrorDomain {
                    let code = FunctionsErrorCode(rawValue: error.code)
                    let message = error.localizedDescription
                    let details = error.userInfo[FunctionsErrorDetailsKey]
                    logError("Cloud function error. Code: \(String(describing: code)), Message: \(message), Details: \(String(describing: details))")
                } else {
                    logError(error!.localizedDescription)
                }
                onComplete(nil, error)
                return
            }

            //check response type
            var data = response
            dataKeys?.forEach { data = (data as? [String: Any])?[$0] }
            guard let result = data as? T else {
                let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Response type not expected"])
                logError(error.localizedDescription)
                onComplete(nil, error)
                return
            }

            //check additional error
            if let errString = otherResponseHandler?(result) {
                let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: errString])
                logError(error.localizedDescription)
                onComplete(nil, error)
                return
            }

            //return the result
            onComplete(result, nil)
        }
    }

    static func getSEVenue(url: String, _ onComplete: @escaping ([[String: String?]]?, Error?) -> Void) {
        httpsCallable("getSEVenue", params: ["url": url], onComplete: onComplete) { (data) -> String? in
            if data.count == 0 {
                LogMessage.create(type: .Error, title: #function, details: "Empty tenants, this is invalid SE QR code")
                return "Empty tenants, this is invalid SE QR code"
            }
            return nil
        }
    }

    static func postSEEntry(safeEntryTenant: SafeEntryTenant, groupIDs: [String] = [], actionType: String, _ onComplete: @escaping ([String: String]?, Error?) -> Void) {
        var dataDict = [String: Any]()
        if !groupIDs.isEmpty {
            var groupIDsFormatted: [[String: String]] = []
            for familyMember in groupIDs {
                groupIDsFormatted.append(["id": familyMember])
            }
            dataDict["groupIds"] = groupIDsFormatted
        }
        dataDict["venueId"] = safeEntryTenant.venueId
        dataDict["tenantId"] = safeEntryTenant.tenantId
        dataDict["actionType"] = actionType
        httpsCallable("postSEEntry", idKey: "id", params: dataDict, onComplete: onComplete)
    }

    static func getSESelfCheck(_ onComplete: @escaping ([[String: Any]]?, Error?) -> Void) {
        httpsCallable("getSESelfCheck", idKey: "nric", dataKeys: ["data"], onComplete: onComplete)
    }
}
