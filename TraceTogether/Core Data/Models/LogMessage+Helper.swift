//
//  LogMessage+Helper.swift
//  OpenTraceTogether

import Foundation
import CoreData
import UIKit
import FirebaseAnalytics

extension LogMessage {

    static func create(type: LogMessage.LogType, title: String, details: [String: String], collectable: Bool = false, timestamp: Date = Date(), debugMessage: String? = nil) {
        create(type: type, title: title, details: convertToDetails(details), collectable: collectable, timestamp: timestamp, debugMessage: debugMessage)
    }

    static func create(type: LogMessage.LogType, title: String, details: String? = nil, collectable: Bool = true, timestamp: Date = Date(), debugMessage: String? = nil) {
        if let debugMessage = debugMessage {
            Logger.DLog( debugMessage, functionName: title)
        }
        guard collectable || DebugTools.isDebug() || DebugTools.isInternalRelease() else {
            return
        }
        if type == .Error || type == .Fatal {
            Analytics.logEvent("app_error", parameters: ["title": title, "details": details ?? "no details"])
            #if DEBUG || INTERNALRELEASE
            print("\(title): \(details ?? "No details")")
            #endif
        }
        Services.database.performInBackground { context in
            let logMessage = LogMessage(context: context)
            logMessage.timestamp = timestamp
            logMessage.title = title
            logMessage.details = details
            logMessage.type = type
            logMessage.collectable = collectable
            do {
                try context.save()
            } catch {
                // todo: crashlytics
                print("Could not save. \(error)")
                AnalyticManager.logEvent(eventName: "Err_LogMessage", param: ["Error": "Error saving LogMessages \(error.localizedDescription)"])
            }
        }
    }

    static func deleteAll() {
        Services.database.performInBackground { context in
            let fetchRequest: NSFetchRequest<LogMessage> = LogMessage.fetchRequest()
            fetchRequest.includesPropertyValues = false
            do {
                let logMessages = try context.fetch(fetchRequest)
                for logMessage in logMessages {
                    context.delete(logMessage)
                }
                try context.save()
            } catch {
                print("Could not perform delete. \(error)")
                AnalyticManager.logEvent(eventName: "Err_LogMessage", param: ["Error": "Error deleting LogMessage objects: \(error.localizedDescription)"])
            }
        }
    }

    static private func convertToDetails(_ payload: [String: String]) -> String {
        return payload.sorted(by: <).map { "\($0.key):\($0.value)" }.joined(separator: " | ")
    }

    static func logAppStart(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        let payload: [String: String] = [
            "osVer": UIDevice.current.systemVersion,
            "appVer": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "",
            "model": DeviceIdentifier.modelName,
            "idType": UserDefaults.standard.string(forKey: "idType") ?? "",
            "id": String((try? SecureStore.readCredentials(service: "nricService", accountName: "id"))?.password.suffix(4) ?? "")
        ]
        LogMessage.create(type: .Info, title: "AppStart", details: payload, collectable: true)
    }

    static func logBluetrace() {
        Services.database.performInBackground { context in
            let lastRecordTime = try? context.fetch(Encounter.fetchRequestForLastRecord()).first?.timestamp
            let totalRecords = (try? context.fetch(Encounter.fetchRequestForTotalRecords()))?.count
            let v3LastRecordTime = try? context.fetch(V3Encounter.fetchRequestForLastRecord()).first?.timestamp
            let v3totalRecords = (try? context.fetch(V3Encounter.fetchRequestForTotalRecords()))?.count
            let liteLastRecordTime = try? context.fetch(LiteEncounter.fetchRequestForLastRecord()).first?.timestamp
            let liteTotalRecords = (try? context.fetch(LiteEncounter.fetchRequestForTotalRecords()))?.count
            let df = DateFormatter.appDateFormatter(format: "yy-MM-dd HH:mm:ss")
            let payload: [String: String] = [
                "btLast": lastRecordTime == nil ? "none" : df.string(from: lastRecordTime!),
                "btTotal": String(totalRecords ?? 0),
                "btV3Last": v3LastRecordTime == nil ? "none" : df.string(from: v3LastRecordTime!),
                "btv3Total": String(v3totalRecords ?? 0),
                "btlLast": liteLastRecordTime == nil ? "none" : df.string(from: liteLastRecordTime!),
                "btlTotal": String(liteTotalRecords ?? 0),
            ]
            LogMessage.create(type: .Info, title: "Bluetrace", details: payload, collectable: true)
        }
    }

    static func removeCollectableLogsMoreThan14DaysAgo() {
        Services.database.performInBackground { context in
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = LogMessage.fetchRequest()
            let date14DaysAgo = Calendar.appCalendar.date(byAdding: .day, value: SafeEntryConfig.LogHistoryDays, to: Date())!
            fetchRequest.predicate = NSPredicate(format: "collectable == true and timestamp < %@", date14DaysAgo as NSDate)

            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            _ = try? context.execute(deleteRequest)
        }
    }

    static func convertAllCollectableToCSV(completion: @escaping (URL, Error?) -> Void) {
        Services.database.performInBackground { context in
            let fetchRequest: NSFetchRequest<LogMessage> = LogMessage.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "collectable == true")

            let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            let id = String((try? SecureStore.readCredentials(service: "nricService", accountName: "id"))?.password.suffix(4) ?? "NO_ID")
            let fileDate = DateFormatter.appDateFormatter(format: "yyMMdd_HHmmss").string(from: Date())
            let fileName = "\(fileDate)_\(id)"
            let fileURL = cacheDir.appendingPathComponent("\(fileName).csv")
            var error: Error?
            let df = DateFormatter.appDateFormatter(format: "yy-MM-dd HH:mm:ss")
            var csv = ""

            do {
                let logs: [LogMessage] = try context.fetch(fetchRequest)
                if logs.isEmpty {
                    error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "You don't have any new logs"])
                } else {
                    csv.appendLine("DATE,TYPE,TITLE,DETAILS")
                }

                var index = 0
                for log in logs {
                    var details = log.details ?? ""
                    if details.contains(",") {
                        details = "\"\(details.replacingOccurrences(of: "\"", with: "\"\""))\""
                    }
                    let row: [String] = [
                        log.timestamp != nil ? df.string(from: log.timestamp!) : "",
                        log.type.toString(),
                        log.title ?? "",
                        details
                    ]
                    csv.appendLine(row.joined(separator: ","))

                    //append to file after every 1000 lines to make it lighter on memory
                    if index >= 1000 {
                        try? csv.append(to: fileURL)
                        csv = ""
                        index = 0
                    } else {
                        index += 1
                    }
                }
            } catch {
                AnalyticManager.logEvent(eventName: "convertAllCollectableToCSV", param: ["error": error.localizedDescription])
                csv.appendLine("\(df.string(from: Date())),\(LogMessage.LogType.Error.toString()),CSVError,\(error.localizedDescription)")
            }
            if !csv.isEmpty {
                try? csv.append(to: fileURL)
            }

            DispatchQueue.main.async { completion(fileURL, error) }
        }
    }

    static func deleteCollectableCSV(in fileURL: URL, includingCoreData: Bool) {
        try? FileManager.default.removeItem(at: fileURL)
        guard includingCoreData else {
            return
        }
        Services.database.performInBackground { context in
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = LogMessage.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "collectable == true")

            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            _ = try? context.execute(deleteRequest)
        }
    }

}
