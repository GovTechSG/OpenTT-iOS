//
//  V3Encounter+EncounterRecord.swift
//  OpenTraceTogether

import Foundation
import CoreData

extension V3EncounterRecord {

    func saveToCoreData() {
        Services.database.performInBackground { context in

            let entity = NSEntityDescription.entity(forEntityName: "V3Encounter", in: context)!
            let v3Encounter = V3Encounter(entity: entity, insertInto: context)
            v3Encounter.set(encounterStruct: self)

            do {
                try context.save()
            } catch {
                // todo: crashlytics
                print("Could not save V3Encounter. \(error)")
                LogMessage.create(type: .Error, title: #function, details: "Could not save V3Encounter. \(error)")
            }
        }
    }
}
