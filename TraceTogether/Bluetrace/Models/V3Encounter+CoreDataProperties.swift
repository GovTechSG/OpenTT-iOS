//
//  V3Encounter+CoreDataProperties.swift
//  OpenTraceTogether

import Foundation
import CoreData

extension V3Encounter {

    enum CodingKeys: String, CodingKey {
        case timestamp
        case msg
        case role
    }

    @NSManaged public var msg: String?
    @NSManaged public var role: String?
    @NSManaged public var timestamp: Date?

    func set(encounterStruct: V3EncounterRecord) {
        setValue(encounterStruct.timestamp, forKeyPath: "timestamp")
        setValue(encounterStruct.msg, forKeyPath: "msg")
        setValue(encounterStruct.role, forKeyPath: "role")
    }

    // MARK: - Encodable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Int(timestamp!.timeIntervalSince1970), forKey: .timestamp)
        try container.encode(msg, forKey: .msg)
        try container.encode(role, forKey: .role)
    }

    @nonobjc public class func fetchRequestForRecords() -> NSFetchRequest<V3Encounter> {
        let fetchRequest = NSFetchRequest<V3Encounter>(entityName: "V3Encounter")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        return fetchRequest
    }

    @nonobjc public class func fetchRequestForLastRecord() -> NSFetchRequest<V3Encounter> {
        let fetchRequest = NSFetchRequest<V3Encounter>(entityName: "V3Encounter")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        fetchRequest.fetchLimit = 1
        return fetchRequest
    }

    @nonobjc public class func fetchRequestForTotalRecords() -> NSFetchRequest<V3Encounter> {
        let fetchRequest = NSFetchRequest<V3Encounter>(entityName: "V3Encounter")
        fetchRequest.includesPropertyValues = false
        return fetchRequest
    }
}
