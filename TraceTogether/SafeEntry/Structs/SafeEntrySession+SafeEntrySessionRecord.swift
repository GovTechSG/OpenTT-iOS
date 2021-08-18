//
//  SafeEntrySession+SafeEntrySessionRecord.swift
//  OpenTraceTogether

import Foundation
import UIKit
import CoreData

extension SafeEntrySessionRecord {

    func saveToCoreData() {
        Services.database.performInBackground { managedContext in
            let entity = NSEntityDescription.entity(forEntityName: "SafeEntrySession", in: managedContext)!
            let safeEntrySession = SafeEntrySession(entity: entity, insertInto: managedContext)
            safeEntrySession.set(safeEntrySessionStruct: self)
            do {
                try managedContext.save()
            } catch {
                print("Could not save SafeEntrySession. \(error)")
                LogMessage.create(type: .Error, title: #function, details: "Could not save SafeEntrySession. \(error)")
            }
        }
    }

    func updateRecordInCoreData() {

    }
}
