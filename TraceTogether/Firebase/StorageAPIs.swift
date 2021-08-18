//
//  StorageAPIs.swift
//  OpenTraceTogether

import Foundation
import FirebaseStorage
import FirebaseFunctions
import CoreData

struct StorageAPIs {

    #if DEBUG
    static private let logStorageURL = "XX://xxx-xxx-xxx-log"
    #else
    static private let logStorageURL = "XX://xxx-xxx-xxx-log"
    #endif

    static func uploadAllCollectableLogs(_ completion: ((Error?) -> Void)?) {
        LogMessage.create(type: .Info, title: #function, details: "")
        LogMessage.convertAllCollectableToCSV { (fileURL, error) in
            guard error == nil else {
                AnalyticManager.logEvent(eventName: "uploadAllCollectableLogs", param: ["Error": "Error converting to CSV: \(error!.localizedDescription)"])
                DispatchQueue.main.async { completion?(error) }
                return
            }
            let today = DateFormatter.appDateFormatter(format: "yyyyMMdd").string(from: Date())
            let fileRef = Storage.storage(url: logStorageURL).reference().child("XXXXX/\(today)/\(fileURL.lastPathComponent)")
            fileRef.putFile(from: fileURL, metadata: nil) { (_, error) in
                if let error = error {
                    AnalyticManager.logEvent(eventName: "uploadAllCollectableLogs", param: ["error": error.localizedDescription])
                }
                LogMessage.deleteCollectableCSV(in: fileURL, includingCoreData: error == nil)
                DispatchQueue.main.async { completion?(error) }
            }
        }
    }

    static func uploadAllEncounter(uploadCode: String, _ completion: ((Error?) -> Void)?) {
        uploadAllEncounter(uploadCode: uploadCode) { (error, errorDetails) in
            if let error = error {
                LogMessage.create(type: .Error, title: "getUploadTokenV2", details: errorDetails)
                completion?(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: error]))
            } else {
                completion?(nil)
            }
        }
    }

    static private func uploadAllEncounter(uploadCode: String, _ completion: @escaping (String?, String?) -> Void) {
        let ttId = UserDefaults.standard.string(forKey: "ttId") ?? "Unknown"
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let dataDict = ["uploadCode": uploadCode, "ttId": ttId, "appVersion": appVersion]
        let functions = Functions.functions(region: "XX")
        let uploadFailErrMsg = NSLocalizedString("UploadFailedPlsTryAgainLater", comment: "Upload failed. Please try again later.")
        let invalidPinErrMsg = NSLocalizedString("InvalidUploadCode", comment: "Invalid upload code")

        functions.httpsCallable("getUploadTokenV2").call(dataDict) { (result, error) in
            guard error == nil else {
                return completion(invalidPinErrMsg, error!.localizedDescription)
            }
            guard let token = (result?.data as? [String: Any])?["token"] as? String else {
                return completion(invalidPinErrMsg, "Token not found")
            }
            self.uploadAllEncounter(token: token) { errorString in
                if let errorString = errorString {
                    return completion(uploadFailErrMsg, errorString)
                } else {
                    return completion(nil, nil)
                }
            }
        }
    }

    static private func uploadAllEncounter(token: String, _ completion: @escaping (String?) -> Void) {
        let manufacturer = "Apple"
        let model = DeviceIdentifier.modelName
        let ttId = UserDefaults.standard.string(forKey: "ttId") ?? "Unknown"
        let todayDate = DateFormatter.appDateFormatter(format: "yyyy-MM-dd_HH-mm-ss").string(from: Date())
        let file = "StreetPassRecord_\(manufacturer)_\(model)_\(todayDate).json"
        let managedContext = Services.database.context
        let recordsFetchRequest: NSFetchRequest<Encounter> = Encounter.fetchRequestForRecords()
        let liteRecordsFetchRequest: NSFetchRequest<LiteEncounter> = LiteEncounter.fetchRequestForRecords()
        let btV3RecordsFetchRequest: NSFetchRequest<V3Encounter> = V3Encounter.fetchRequestForRecords()
        let deviceInfo: DeviceInfo = DeviceInfo(os: "ios", model: model)
        let storageUrl = PlistHelper.getvalueFromInfoPlist(withKey: "FIREBASE_STORAGE_URL") ?? ""

        managedContext!.perform {
            guard let records = try? recordsFetchRequest.execute() else {
                return completion("Error fetching V2 records")
            }
            guard let liteRecords = try? liteRecordsFetchRequest.execute() else {
                return completion("Error fetching lite records")
            }
            guard let btV3Records = try? btV3RecordsFetchRequest.execute() else {
                return completion("Error fetching V3 records")
            }

            let data = UploadFileData(token: token, device: deviceInfo, records: records, btLiteRecords: liteRecords, btV3Records: btV3Records, ttId: ttId)

            guard let json = try? JSONEncoder().encode(data) else {
                return completion("Error serializing data")
            }
            guard let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                return completion("Error locating user documents directory")
            }

            let fileURL = directory.appendingPathComponent(file)

            do {
                try json.write(to: fileURL, options: [])
            } catch {
                return completion("Error writing to file")
            }

            let fileRef = Storage.storage(url: storageUrl).reference().child("streetPassRecords/\(file)")

            _ = fileRef.putFile(from: fileURL, metadata: nil) { _, error in
                do {
                    try FileManager.default.removeItem(at: fileURL)
                } catch {
                    completion(error.localizedDescription)
                    return
                }
                completion(error?.localizedDescription)
            }
        }
    }
}
