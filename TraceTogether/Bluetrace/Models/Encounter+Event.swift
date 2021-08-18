//
//  Encounter+Event.swift
//  OpenTraceTogether


import UIKit
import CoreData

extension Encounter {

    enum Event: String {
        case scanningStarted = "Scanning started"
        case scanningStopped = "Scanning stopped"
    }

    static func timestamp(for event: Event) {
        Services.database.performInBackground { managedContext in
            let entity = NSEntityDescription.entity(forEntityName: "Encounter", in: managedContext)!
            let encounter = Encounter(entity: entity, insertInto: managedContext)
            encounter.msg = event.rawValue
            encounter.timestamp = Date()
            encounter.v = nil
            do {
                try managedContext.save()
            } catch {
                print("Could not save Encounter. \(error)")
                LogMessage.create(type: .Error, title: #function, details: "Could not save Encounter. \(error)")
            }
        }
    }

}
