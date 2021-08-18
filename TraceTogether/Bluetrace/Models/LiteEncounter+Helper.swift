//
//  LiteEncounter+Helper.swift
//  OpenTraceTogether

import UIKit
import CoreData

extension LiteEncounter {
    static func create(msg: String, rssi: NSNumber, txPower: NSNumber?, timestamp: Date = Date()) {
        Services.database.performInBackground { context in
            let liteEncounter = LiteEncounter(context: context)
            liteEncounter.msg = msg
            liteEncounter.rssi = rssi
            liteEncounter.txPower = txPower
            liteEncounter.timestamp = timestamp
            do {
                try context.save()
            } catch {
                // todo: crashlytics
                print("Could not save. \(error)")
                LogMessage.create(type: .Error, title: #function, details: "Could not save. \(error)")
            }
        }
    }
}
