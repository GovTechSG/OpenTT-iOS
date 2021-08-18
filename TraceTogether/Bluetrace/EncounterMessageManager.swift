//
//  EncounterMessageManager.swift
//  OpenTraceTogether

import Foundation
import FirebaseFunctions

class EncounterMessageManager {
    let userDefaultsTempIdKey = "TEMP_ID"
    let userDefaultsTempIdArrayKey = "TEMP_IDS_ARRAY"
    let userDefaultsAdvtKey = "ADVT_DATA"
    let userDefaultsBatchExpiryKey = "BATCH_TEMPID_EXPIRY"
    let userDefaultsValidTempIdExpiryKey = "VALID_TEMPID_EXPIRY"

    static let shared = EncounterMessageManager()

    lazy var functions = Functions.functions(region: "asia-east2")

    var tempId: String? {
        guard var tempIds = UserDefaults.standard.array(forKey: userDefaultsTempIdArrayKey) as! [[String: Any]]? else {
            return "not_found"
        }

        tempIds.removeAll(where: {
            Date() > Date(timeIntervalSince1970: $0["expiryTime"] as! Double)
        })

        UserDefaults.standard.set(tempIds, forKey: self.userDefaultsTempIdArrayKey)

        guard let validTempID = tempIds.first?["tempID"] as? String else {
            LogMessage.create(type: LogMessage.LogType.Info, title: "Using empty tempID")
            return ""
        }

        if let validTempIDExpiry = tempIds.first?["expiryTime"] as? Double {
            let validTempIDExpiryDate = Date(timeIntervalSince1970: validTempIDExpiry)
            UserDefaults.standard.set(validTempIDExpiryDate, forKey: self.userDefaultsValidTempIdExpiryKey)
        }

        UserDefaults.standard.set(validTempID, forKey: self.userDefaultsTempIdKey)

        return validTempID
        //        return UserDefaults.standard.string(forKey: userDefaultsTempIdArrayKey)
    }

    var encodedAdvtPayload: Data? {
        return UserDefaults.standard.data(forKey: userDefaultsAdvtKey)
    }

    var tempIDExpiry: Date? {
        return UserDefaults.standard.object(forKey: userDefaultsValidTempIdExpiryKey) as? Date
    }

    // This variable stores the expiry date of the broadcast message. At the same time, we will use this expiry date as the expiry date for the encryted advertisement payload
    var advtPayloadExpiry: Date? {
        return UserDefaults.standard.object(forKey: userDefaultsBatchExpiryKey) as? Date
    }

    func setup() {
        // Check encoded payload validity
        if advtPayloadExpiry == nil ||  Date() > advtPayloadExpiry! {
            switch BluetraceConfig.ProtocolVersion {
            case 2:
                fetchBatchTempIdsFromFirebase { [unowned self](error: Error?, resp: (tempIds: [[String: Any]], batchRefreshDate: Date)?) in
                    guard let response = resp else {
                        Logger.DLog("No response, Error: \(String(describing: error))")
                        return
                    }
                    _ = self.setAdvtPayloadIntoUserDefaults(response)
                    UserDefaults.standard.set(response.tempIds, forKey: self.userDefaultsTempIdArrayKey)

                }
            default:
                Logger.DLog("Error setting up Peripheral")
            }
        }
    }

    // For Central to write to Peripheral
    // For Peripheral to cache AdvtPayload with validTempId
    func getValidTempId(onComplete: @escaping (String?) -> Void) {
        // check batchRefreshDate
        if advtPayloadExpiry == nil ||  Date() > advtPayloadExpiry! {
            fetchBatchTempIdsFromFirebase { [unowned self](error: Error?, resp: (tempIds: [[String: Any]], batchRefreshDate: Date)?) in
                guard let response = resp else {
                    Logger.DLog("No response, Error: \(String(describing: error))")
                    return
                }

                _ = self.setAdvtPayloadIntoUserDefaults(response)
                UserDefaults.standard.set(response.batchRefreshDate, forKey: self.userDefaultsBatchExpiryKey)

                var dataArray = response

                dataArray.tempIds.removeAll(where: {
                    Date() > Date(timeIntervalSince1970: $0["expiryTime"] as! Double)
                })

                UserDefaults.standard.set(response.tempIds, forKey: self.userDefaultsTempIdArrayKey)

                guard let validTempID = dataArray.tempIds.first?["tempID"] as? String else { return }

                UserDefaults.standard.set(validTempID, forKey: self.userDefaultsTempIdKey)

                if let validTempIDExpiry = dataArray.tempIds.first?["expiryTime"] as? Double {
                    let validTempIDExpiryDate = Date(timeIntervalSince1970: validTempIDExpiry)
                    UserDefaults.standard.set(validTempIDExpiryDate, forKey: self.userDefaultsValidTempIdExpiryKey)
                }

                onComplete(validTempID)
                return

            }
        }

        // we know that tempIdBatch array has not expired, now find the latest usable tempId

        if let msg = tempId {
            onComplete(msg)
        } else {
            // this is not part of usual expected flow, just run setup and be done with it
            setup()
            onComplete(nil)
        }
    }

    func fetchBatchTempIdsFromFirebase(onComplete: ((Error?, ([[String: Any]], Date)?) -> Void)?) {
        Logger.DLog("Fetching Batch of tempIds from firebase")
        let ttId = UserDefaults.standard.string(forKey: "ttId") ?? "Unknown"
        if ttId == "Unknown" {
            print("ttId Unknown - do not registerFCMToken")
            onComplete?(nil, nil)
            return
        }
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let data = ["ttId": ttId, "appVersion": appVersion]
        LogMessage.create(type: LogMessage.LogType.Info, title: "Fetch new batch of TempIDs")
        functions.httpsCallable("getTempIDsV2").call(data) { (result, error) in
            // Handle error
            guard error == nil else {
                if let error = error as NSError? {
                    if error.domain == FunctionsErrorDomain {
                        let code = FunctionsErrorCode(rawValue: error.code)
                        let message = error.localizedDescription
                        let details = error.userInfo[FunctionsErrorDetailsKey]
                        Logger.DLog("Cloud function error. Code: \(String(describing: code)), Message: \(message), Details: \(String(describing: details))")
                        onComplete?(error, nil)
                        return
                    }
                } else {
                    Logger.DLog("Cloud function error, unable to convert error to NSError.\(error!)")
                }
                onComplete?(error, nil)
                return
            }

            // Handle getting a batch of tempIds from Firebase function
            guard var tempIdsInBase64 = (result?.data as? [String: Any])?["tempIDs"] as? [[String: Any]],
                var tempIdRefreshTime = (result?.data as? [String: Any])?["refreshTime"] as? Double else {
                    Logger.DLog("Unable to get tempId or refreshTime from Firebase. result of function call: \(String(describing: result))")
                    onComplete?(NSError(domain: "BM", code: 9999, userInfo: nil), nil)
                    return
            }

            #if DEBUG
                tempIdsInBase64 = Array(tempIdsInBase64.prefix(6))
                tempIdRefreshTime = tempIdsInBase64[3]["expiryTime"] as! Double
            #endif
            onComplete?(nil, (tempIdsInBase64, Date(timeIntervalSince1970: tempIdRefreshTime)))
        }
    }

    func setAdvtPayloadIntoUserDefaults(_ response: (tempIds: [[String: Any]], batchRefreshDate: Date)) -> Data? {

        var dataArray = response

        // Pop out expired tempIds
        dataArray.tempIds.removeAll(where: {
            Date() > Date(timeIntervalSince1970: $0["expiryTime"] as! Double)
        })

        guard let validTempID = dataArray.tempIds.first?["tempID"] as? String else { return nil }

        let peripheralCharStruct = PeripheralCharacteristicsDataV2(mp: DeviceIdentifier.getModel(), id: validTempID, o: BluetraceConfig.OrgID, v: BluetraceConfig.ProtocolVersion)

        do {
            let encodedPeriCharStruct = try JSONEncoder().encode(peripheralCharStruct)
            if let string = String(data: encodedPeriCharStruct, encoding: .utf8) {
                Logger.DLog("UserDefaultsv2 \(string)")
            } else {
                print("not a valid UTF-8 sequence")
            }

            UserDefaults.standard.set(encodedPeriCharStruct, forKey: self.userDefaultsAdvtKey)
            UserDefaults.standard.set(response.batchRefreshDate, forKey: self.userDefaultsBatchExpiryKey)
            return encodedPeriCharStruct
        } catch {
            Logger.DLog("Error: \(error)")
        }

        return nil
    }

    // Verify that tempID is valid before caching AdvtPayload with it
    func getValidAdvtPayload() -> Data? {

        guard let validTempID = tempId else { return nil }

        let peripheralCharStruct = PeripheralCharacteristicsDataV2(mp: DeviceIdentifier.getModel(), id: validTempID, o: BluetraceConfig.OrgID, v: BluetraceConfig.ProtocolVersion)

        do {
            let encodedPeriCharStruct = try JSONEncoder().encode(peripheralCharStruct)
            if let string = String(data: encodedPeriCharStruct, encoding: .utf8) {
                Logger.DLog("UserDefaultsv2 \(string)")
            } else {
                print("not a valid UTF-8 sequence")
            }

            UserDefaults.standard.set(encodedPeriCharStruct, forKey: self.userDefaultsAdvtKey)

            return encodedPeriCharStruct
        } catch {
            Logger.DLog("Error: \(error)")
        }

        return nil
    }

}
