//
//  Encounter+EncounterRecord.swift
//  OpenTraceTogether


import UIKit
import CoreData

extension EncounterRecord {

    func saveToCoreData() {
        DispatchQueue.main.async {
            let entity = NSEntityDescription.entity(forEntityName: "Encounter", in: Services.database.context)!
            let encounter = Encounter(entity: entity, insertInto: Services.database.context)
            encounter.set(encounterStruct: self)
            do {
                try Services.database.context.save()
            } catch {
                print("Could not save Encounter. \(error)")
                LogMessage.create(type: .Error, title: #function, details: "Could not save Encounter. \(error)")
            }
        }
    }

}
