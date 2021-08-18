//
//  DatabaseServiceProtocol.swift
//  OpenTraceTogether

import Foundation
import CoreData

protocol DatabaseServiceProtocol {

    /// Use this to create custom db logic. Try not to use this since create/get/delete/save are sufficient enough
    var context: NSManagedObjectContext! { get }

    /// Create a new object.
    func create<T: NSManagedObject>(_ type: T.Type) -> T

    /// Get object with certain config and subscribe to changes.
    func getFetchResultsController<T: NSManagedObject>(_ type: T.Type, delegate: NSFetchedResultsControllerDelegate?, _ config: ((NSFetchRequest<T>) -> Void)?) -> NSFetchedResultsController<T>

    /// Get object with certain config.
    func get<T: NSManagedObject>(_ type: T.Type, _ config: ((NSFetchRequest<T>) -> Void)?) -> [T]

    /// Delete all object with certain class synchronously. To perform in background, wrap it with `performInBackground`.
    func delete<T: NSManagedObject>(_ type: T.Type)

    /// Delete all object with certain class and predicate synchronously. To perform in background, wrap it with `performInBackground`.
    func delete<T: NSManagedObject>(_ type: T.Type, predicate: NSPredicate?)

    /// Save db synchronously. To perform in background, wrap it with `performInBackground`.
    func save()

    /// Perform db task in background.
    func performInBackground(_ task: @escaping () -> Void)

    /// Perform db task in background.
    func performInBackground(_ task: @escaping (NSManagedObjectContext) -> Void)
}
