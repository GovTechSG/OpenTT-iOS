//
//  EncounterDailyService.swift
//  OpenTraceTogether

import Foundation
import CoreData

class EncounterServiceDaily: NSObject, NSFetchedResultsControllerDelegate {

    private var fetched: NSFetchedResultsController<Encounter>?
    private var fetchedV3: NSFetchedResultsController<V3Encounter>?
    private var fetchedLite: NSFetchedResultsController<LiteEncounter>?

    var observers: Observers = .init()
    var includeValue: Bool

    init(includeValue: Bool = false) {
        self.includeValue = includeValue
    }

    func startObserving(for date: Date) {
        _ = fetchObjects(for: date)
    }

    func fetchObjects(for date: Date) -> [EncounterProtocol] {
        fetched = getFetchResultsController(for: date)
        fetchedV3 = getFetchResultsController(for: date)
        fetchedLite = getFetchResultsController(for: date)
        return ([fetched, fetchedV3, fetchedLite] as! [NSFetchedResultsController<NSManagedObject>?])
            .reduce([], { $0 + (($1?.fetchedObjects as? [EncounterProtocol]) ?? []) })
    }

    private func getFetchResultsController<T: NSManagedObject>(_ type: T.Type = T.self, for date: Date) -> NSFetchedResultsController<T> {
        let todayStart = Calendar.appCalendar.startOfDay(for: date)
        let nextDayStart = Calendar.appCalendar.date(byAdding: .day, value: 1, to: todayStart)!
        let resultController = Services.database.getFetchResultsController(type, delegate: self) {
            $0.includesPropertyValues = self.includeValue
            $0.predicate = NSPredicate(format: "timestamp >= %@ and timestamp < %@ and msg != %@ and msg != %@", todayStart as NSDate, nextDayStart as NSDate, Encounter.Event.scanningStarted.rawValue, Encounter.Event.scanningStopped.rawValue)
            $0.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        }
        do {
            try resultController.performFetch()
        } catch {
            LogMessage.create(type: .Error, title: #function, details: error.localizedDescription)
        }
        return resultController
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        observers.notify()
    }
}
