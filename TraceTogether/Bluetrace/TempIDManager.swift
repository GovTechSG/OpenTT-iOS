//
//  TempIDManager.swift
//  OpenTraceTogether

import Foundation
import FirebaseFunctions

class TempIDManager {
    static let shared = TempIDManager()

    lazy var functions = Functions.functions(region: "XX")
    var debounceInterval = TimeInterval(60)
    var debounceDate: Date?

    func getTempID() -> String {
        if currentTempID == nil {
            return ""
        }
        return currentTempID!
    }

    func getShortTempID() -> String {
        if currentShortTempID == nil {
            return ""
        }
        return currentShortTempID!
    }

    func getTempIDExpiryDate() -> Date? {
        return currentTempIDExpiryDate
    }

    func getShortTempIDExpiryDate() -> Date? {
        return currentShortTempIDExpiryDate
    }

    func getBatchRefreshDate() -> Date? {
        return batchRefreshDate
    }

    func getLastBatchReceivedDate() -> Date? {
        return lastBatchReceivedDate
    }

    func updateTempIDIfNecessary() {
        #if DEBUG || INTERNALRELEASE
        LogMessage.create(type: .Info, title: "TempIDManager>updateTempIDIfNecessary", details: "start")
        #endif
        if debounceDate != nil && Date() < debounceDate! {
            #if DEBUG || INTERNALRELEASE
            LogMessage.create(type: .Info, title: "TempIDManager>updateTempIDIfNecessary", details: "Debounced tempID update, try again later at \(debounceDate ?? Date())")
            #endif
            return
        }

        if (currentTempIDExpiryDate != nil && Date() > currentTempIDExpiryDate!) {
            popNextValidTempID()
            V2Peripheral.generateAndCacheAdvtPayload()
            debounceDate = Date() + debounceInterval
        }

        if (currentShortTempIDExpiryDate != nil && Date() > currentShortTempIDExpiryDate!) {
            popNextValidShortTempID()
            debounceDate = Date() + debounceInterval
        }

        if currentTempID == nil || currentTempIDExpiryDate == nil || tempIDBatchItems == nil || shortTempIDBatchItems == nil || tempIDBatchItems!.count == 0 || shortTempIDBatchItems!.count == 0 || batchRefreshDate == nil || Date() > batchRefreshDate! {
            debounceDate = Date() + debounceInterval
            DispatchQueue.global(qos: .background).async {
                self.fetchNewBatchAndUpdateAdvtPayload()
            }
        }
    }

    // Pop next valid tempID from tempIDBatchItems into currentTempID
    func popNextValidTempID() {
        // Remove expired tempIDs from tempIDBatchItems
        let validTempIDBatchItems = tempIDBatchItems?.filter { batchItem in
            if let expiryTime = batchItem["expiryTime"] as? Double {
                return Date() < Date(timeIntervalSince1970: expiryTime)
            } else {
                return false
            }
        }
        tempIDBatchItems = validTempIDBatchItems

        // Retrieve the next valid tempID and expiry date from tempIDBatchItems
        if let nextTempIDBatchItem = tempIDBatchItems?.first {
            currentTempID = nextTempIDBatchItem["tempID"] as? String
            if let expiryTime = nextTempIDBatchItem["expiryTime"] as? Double {
                currentTempIDExpiryDate = Date(timeIntervalSince1970: expiryTime)
                LogMessage.create(type: .Info, title: #function, details: "expiryDate - \(expiryTime))", timestamp: Date())
            } else {
                currentTempIDExpiryDate = nil
            }
        }
    }

    // Pop next valid shorttempID from shortTempIDBatchItems into currentShortTempID
    func popNextValidShortTempID() {
        // Remove expired shorttempIDs from shortTempIDBatchItems
        let validShortTempIDBatchItems = shortTempIDBatchItems?.filter { batchItem in
            if let expiryTime = batchItem["expiryTime"] as? Double {
                return Date() < Date(timeIntervalSince1970: expiryTime)
            } else {
                return false
            }
        }
        shortTempIDBatchItems = validShortTempIDBatchItems

        // Retrieve the next valid shorttempID and expiry date from shortTempIDBatchItems
        if let nextShortTempIDBatchItem = shortTempIDBatchItems?.first {
            currentShortTempID = nextShortTempIDBatchItem["tempID"] as? String
            if let expiryTime = nextShortTempIDBatchItem["expiryTime"] as? Double {
                currentShortTempIDExpiryDate = Date(timeIntervalSince1970: expiryTime)
            } else {
                currentShortTempIDExpiryDate = nil
            }

            #if DEBUG
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
            if let validCurrentShortTempIDExpiryDate = currentShortTempIDExpiryDate {
                let expiry = formatter.string(from: validCurrentShortTempIDExpiryDate)

                LogMessage.create(type: .Info, title: "Pop nextShortTempID", details: "expiryDate - \(expiry))", timestamp: Date())
            }
            #endif
        }
    }

    private var bluetoothObserver: NSObjectProtocol?
    private var isFetching = false

    func fetchNewBatchAndUpdateAdvtPayload(attempt: Int = 0) {

        // Wait until bluetooth is on
        if !BluetraceManager.shared.isBluetoothOn() {
            if bluetoothObserver == nil {
                bluetoothObserver = NotificationCenter.default.addObserver(forName: .bluetoothStateDidChange, object: nil, queue: OperationQueue.main) { [unowned self] _ in
                    self.fetchNewBatchAndUpdateAdvtPayload(attempt: attempt)
                }
            }
            return
        }
        if let observer = bluetoothObserver {
            NotificationCenter.default.removeObserver(observer)
        }

        if isFetching {
            return
        }

        isFetching = true
        FirebaseAPIs.getTempIDsV3 { (_, resp: (tempIDBatchItems: [[String: Any]], shortTempIDBatchItems: [[String: Any]], batchRefreshDate: Date)?) in
            self.isFetching = false

            guard let response = resp else {

                // Schedule another call, retry max 3 times, if still failed, retry another call in 1 hour
                let maxRetry = 3
                let nextAttemptInterval: TimeInterval = attempt < maxRetry ? 5 : 3600
                let nextAttempt = attempt < maxRetry ? attempt + 1 : 0
                DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + nextAttemptInterval) {
                    self.fetchNewBatchAndUpdateAdvtPayload(attempt: nextAttempt)
                }
                return
            }
            self.tempIDBatchItems = response.tempIDBatchItems
            self.shortTempIDBatchItems = response.shortTempIDBatchItems
            self.batchRefreshDate = response.batchRefreshDate
            self.lastBatchReceivedDate = Date()
            self.popNextValidTempID()
            self.popNextValidShortTempID()
            V2Peripheral.generateAndCacheAdvtPayload()
            // V3Peripheral generateAndCacheAdvtPayload is not required because we don't need to cache a JSON object, just advertising the shortTempID directly
        }
    }
}

extension TempIDManager {
    private var currentTempID: String? {
        get {
            return UserDefaults.standard.string(forKey: "currentTempID")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "currentTempID")
        }
    }

    private var currentShortTempID: String? {
        get {
            return UserDefaults.standard.string(forKey: "currentShortTempID")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "currentShortTempID")
        }
    }

    private var currentTempIDExpiryDate: Date? {
        get {
            return UserDefaults.standard.object(forKey: "currentTempIDExpiryDate") as? Date
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "currentTempIDExpiryDate")
        }
    }

    private var currentShortTempIDExpiryDate: Date? {
        get {
            return UserDefaults.standard.object(forKey: "currentShortTempIDExpiryDate") as? Date
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "currentShortTempIDExpiryDate")
        }
    }

    // each is a dict with keys expiryTime and tempID
    private var tempIDBatchItems: [[String: Any]]? {
        get {
            return UserDefaults.standard.array(forKey: "tempIDBatchItems") as? [[String: Any]]
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "tempIDBatchItems")
        }
    }

    private var shortTempIDBatchItems: [[String: Any]]? {
        get {
            return UserDefaults.standard.array(forKey: "shortTempIDBatchItems") as? [[String: Any]]
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "shortTempIDBatchItems")
        }
    }

    private var batchRefreshDate: Date? {
        get {
            return UserDefaults.standard.object(forKey: "batchRefreshDate") as? Date
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "batchRefreshDate")
        }
    }

    // Date by which the latest batch was received from Server
    private var lastBatchReceivedDate: Date? {
        get {
            return UserDefaults.standard.object(forKey: "batchReceivedDate") as? Date
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "batchReceivedDate")
        }
    }
}
