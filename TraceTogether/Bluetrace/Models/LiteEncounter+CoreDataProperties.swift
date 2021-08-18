//
//  LiteEncounter+CoreDataProperties.swift
//  OpenTraceTogether

import Foundation
import CoreData
import UIKit
import CoreBluetooth

extension LiteEncounter {

    enum CodingKeys: String, CodingKey {
        case timestamp
        case msg
        case rssi
        case txPower
    }

    @nonobjc public class func fetchRequestForRecords() -> NSFetchRequest<LiteEncounter> {
        let fetchRequest = NSFetchRequest<LiteEncounter>(entityName: "LiteEncounter")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        return fetchRequest
    }

    @nonobjc public class func fetchRequestForLastRecord() -> NSFetchRequest<LiteEncounter> {
        let fetchRequest = NSFetchRequest<LiteEncounter>(entityName: "LiteEncounter")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        fetchRequest.fetchLimit = 1
        return fetchRequest
    }

    @nonobjc public class func fetchRequestForTotalRecords() -> NSFetchRequest<LiteEncounter> {
        let fetchRequest = NSFetchRequest<LiteEncounter>(entityName: "LiteEncounter")
        fetchRequest.includesPropertyValues = false
        return fetchRequest
    }

    @NSManaged public var timestamp: Date?
    @NSManaged public var msg: String?
    @NSManaged public var rssi: NSNumber?
    @NSManaged public var txPower: NSNumber?

    // MARK: - Encodable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Int(timestamp!.timeIntervalSince1970), forKey: .timestamp)
        try container.encode(msg, forKey: .msg)
        try container.encode(rssi?.doubleValue, forKey: .rssi)
        try container.encode(txPower?.doubleValue, forKey: .txPower)
    }

}
