//
//  DatabaseService.swift
//  OpenTraceTogether

import Foundation
import CoreData
import FirebaseCrashlytics
import FirebaseAnalytics

class DatabaseService: DatabaseServiceProtocol {

    private var persistentContainer: NSPersistentContainer!
    var context: NSManagedObjectContext!

    init(persist: Bool = true) {
        if persist {
            let container = NSPersistentContainer(name: "tracer")
            persistentContainer = container
            context = persistentContainer.viewContext
            container.loadPersistentStores { (_, error) in
                if let error = error {
                    self.logError(error)
                }
                container.viewContext.automaticallyMergesChangesFromParent = true
                container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
                container.viewContext.shouldDeleteInaccessibleFaults = true
            }
        } else {
            let dataModel = NSManagedObjectModel.mergedModel(from: [Bundle.main])!
            let psc = NSPersistentStoreCoordinator(managedObjectModel: dataModel)
            _ = try? psc.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
            let moc = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
            moc.persistentStoreCoordinator = psc
            context = moc
        }
    }

    func getFetchResultsController<T: NSManagedObject>(_ type: T.Type, delegate: NSFetchedResultsControllerDelegate?, _ config: ((NSFetchRequest<T>) -> Void)? = nil) -> NSFetchedResultsController<T> {
        let fetchRequest = getFetchRequest(type)
        config?(fetchRequest)
        let fetchedResultsController = NSFetchedResultsController<T>(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = delegate
        return fetchedResultsController
    }

    func getFetchRequest<T: NSManagedObject>(_ type: T.Type = T.self) -> NSFetchRequest<T> {
        let fetchRequest = NSFetchRequest<T>()
        fetchRequest.entity = NSEntityDescription.entity(forEntityName: NSStringFromClass(type.self), in: context)
        return fetchRequest
    }

    func get<T: NSManagedObject>(_ type: T.Type, _ config: ((NSFetchRequest<T>) -> Void)? = nil) -> [T] {
        let fetchRequest = getFetchRequest(type)
        config?(fetchRequest)
        return (try? context.fetch(fetchRequest)) ?? []
    }

    func create<T: NSManagedObject>(_ type: T.Type) -> T {
        let entityDescription = NSEntityDescription.entity(forEntityName: NSStringFromClass(type.self), in: context)
        return type.init(entity: entityDescription!, insertInto: context)
    }

    func delete<T: NSManagedObject>(_ type: T.Type, predicate: NSPredicate?) {
        context.performAndWait {
            if persistentContainer != nil {
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: NSStringFromClass(type.self))
                fetchRequest.predicate = predicate
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                do { try self.context.execute(deleteRequest) } catch { logError(error) }
            } else {
                get(type) { $0.predicate = predicate }.forEach { context.delete($0) }
            }
        }
    }

    func delete<T: NSManagedObject>(_ type: T.Type) {
        delete(type, predicate: nil)
    }

    func save() {
        if context.hasChanges {
            context.performAndWait {
                do { try self.context.save() } catch { logError(error) }
            }
        }
    }

    func performInBackground(_ task: @escaping () -> Void) {
        context.perform { task() }
    }

    func performInBackground(_ task: @escaping (NSManagedObjectContext) -> Void) {
        context.perform { task(self.context) }
    }

    private func logError(title: String = #function, _ error: Error) {
        Crashlytics.crashlytics().record(error: error)
        Analytics.logEvent("db_error", parameters: ["title": title, "details": error.localizedDescription])
    }
}
