//
//  EncounterService.swift
//  OpenTraceTogether

import Foundation
import CoreData

class EncounterService: EncounterServiceProtocol {

    private lazy var today: EncounterServiceDaily = .init(includeValue: true)

    func addLite(msg: String, rssi: NSNumber, txPower: NSNumber, date: Date) {
        let encounter = Services.database.create(LiteEncounter.self)
        encounter.timestamp = date
        encounter.msg = msg
        encounter.rssi = rssi
        encounter.txPower = txPower
        Services.database.save()
    }

    func add(msg: String, role: String, date: Date) {
        let encounter = Services.database.create(V3Encounter.self)
        encounter.timestamp = date
        encounter.msg = msg
        encounter.role = role
        Services.database.save()
    }

    func addStartScanningMsg(date: Date) {
        let encounter = Services.database.create(Encounter.self)
        encounter.msg = Encounter.Event.scanningStarted.rawValue
        encounter.timestamp = date
        Services.database.save()
    }

    func addStopScanningMsg(date: Date) {
        let encounter = Services.database.create(Encounter.self)
        encounter.msg = Encounter.Event.scanningStopped.rawValue
        encounter.timestamp = date
        Services.database.save()
    }

    func getTotalPerDay(_ date: Date) -> Int {
        return EncounterServiceDaily().fetchObjects(for: date).count
    }

    func observeTodayHighlight(_ weakRef: AnyObject, callback: @escaping () -> Void) {
        today.observers.add(weakRef, callback)
        today.startObserving(for: Date())
    }

    func getTodayHighlight() -> EncounterTodayHighlight {
        let objects = today.fetchObjects(for: Date())
        let total = objects.count
        let fiveMinsAgo = Date(timeIntervalSinceNow: -300)
        let uniqueTotal = Set(objects.filter { $0.timestamp! > fiveMinsAgo }.map { $0.msg }).count
        let upperRange = Int(ceil(Double(uniqueTotal) / 5) * 5)
        let lowerRange = max(upperRange - 4, 0)
        return .init(total: total, nearbyLowerRange: lowerRange, nearbyUpperRange: upperRange)
    }

    func removeData25DaysOld() {
        Services.database.performInBackground {
            let twentyFiveDaysAgo = Calendar.appCalendar.date(byAdding: .day, value: BluetraceConfig.TTLDays, to: Date())!
            let predicateForDel = NSPredicate(format: "timestamp < %@", twentyFiveDaysAgo as NSDate)
            Services.database.delete(Encounter.self, predicate: predicateForDel)
            Services.database.delete(V3Encounter.self, predicate: predicateForDel)
            Services.database.delete(LiteEncounter.self, predicate: predicateForDel)
        }
    }
}
