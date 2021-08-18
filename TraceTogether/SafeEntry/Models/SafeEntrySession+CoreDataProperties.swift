//
//  SafeEntrySession+CoreDataProperties.swift
//  OpenTraceTogether

import Foundation
import CoreData
import UIKit

extension SafeEntrySession {
    enum CodingKeys: String, CodingKey {
        case venueId
        case venueName
        case tenantId
        case tenantName
        case postalCode
        case address
        case checkInDate
        case checkOutDate
        case groupIDs
    }

    @nonobjc public class func fetchRequestForLastCheckInSession() -> NSFetchRequest<SafeEntrySession> {

        let oneDayAgo = Calendar.appCalendar.date(byAdding: .hour, value: SafeEntryConfig.TTLHours, to: Date())!
        let sortByDate = NSSortDescriptor(key: "checkInDate", ascending: false)
        let fetchRequest = NSFetchRequest<SafeEntrySession>(entityName: "SafeEntrySession")
        let predicate = NSPredicate(format: "checkInDate > %@ and checkOutDate == nil", oneDayAgo as NSDate)
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = [sortByDate]

        return fetchRequest
    }

    @nonobjc public class func fetchRequestForLastSafeEntrySession() -> NSFetchRequest<SafeEntrySession> {

        let oneDayAgo = Calendar.appCalendar.date(byAdding: .hour, value: SafeEntryConfig.TTLHours, to: Date())!
        let sortByDate = NSSortDescriptor(key: "checkInDate", ascending: false)
        let fetchRequest = NSFetchRequest<SafeEntrySession>(entityName: "SafeEntrySession")
        let predicate = NSPredicate(format: "checkInDate > %@", oneDayAgo as NSDate)
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = [sortByDate]

        return fetchRequest
    }

    @nonobjc public class func fetchRequestForLastSessionWith(tenantId: String, venueId: String) -> NSFetchRequest<SafeEntrySession> {
        let sortByDate = NSSortDescriptor(key: "checkInDate", ascending: false)
        let fetchRequest = NSFetchRequest<SafeEntrySession>(entityName: "SafeEntrySession")
        let predicate =  NSPredicate(format: "tenantId = %@ AND venueId = %@", tenantId, venueId)
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = [sortByDate]

        return fetchRequest
    }

    @nonobjc public class func fetchRequestForHistoryFromDateOfRegistration() -> NSFetchRequest<SafeEntrySession> {
        var twoWeeksAgo = Calendar.appCalendar.date(byAdding: .day, value: SafeEntryConfig.SEHistoryDays, to: Date())!
        twoWeeksAgo = Calendar.appCalendar.startOfDay(for: twoWeeksAgo)
        var endDate = twoWeeksAgo
        if dateOfRegistration != nil {
            endDate = dateOfRegistration! < twoWeeksAgo ?  twoWeeksAgo : dateOfRegistration!
        }
        let sortByDate = NSSortDescriptor(key: "checkInDate", ascending: false)
        let fetchRequest = NSFetchRequest<SafeEntrySession>(entityName: "SafeEntrySession")
        let predicate = NSPredicate(format: "checkInDate >= %@", endDate as NSDate)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = [sortByDate]

        return fetchRequest
    }

    @nonobjc class func fetchRequestForTenants(tenants: [SafeEntryTenant]) -> NSFetchRequest<SafeEntrySession> {
        let fetchRequest = NSFetchRequest<SafeEntrySession>(entityName: "SafeEntrySession")
        let predicates = tenants.map {
            NSPredicate(format: "tenantId = %@ AND venueId = %@", $0.tenantId!, $0.venueId!)
        }
        let predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
        fetchRequest.predicate = predicate
        return fetchRequest
    }

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SafeEntrySession> {
        return NSFetchRequest<SafeEntrySession>(entityName: "SafeEntrySession")
    }

    @NSManaged public var venueId: String?
    @NSManaged public var venueName: String?
    @NSManaged public var tenantId: String?
    @NSManaged public var tenantName: String?
    @NSManaged public var postalCode: String?
    @NSManaged public var address: String?
    @NSManaged public var checkInDate: Date?
    @NSManaged public var checkOutDate: Date?
    @NSManaged public var groupIDs: [String]?
    @NSManaged public var venue: Venue?

    func set(safeEntrySessionStruct: SafeEntrySessionRecord) {
        setValue(safeEntrySessionStruct.venueId, forKeyPath: "venueId")
        setValue(safeEntrySessionStruct.venueName, forKeyPath: "venueName")
        setValue(safeEntrySessionStruct.tenantId, forKeyPath: "tenantId")
        setValue(safeEntrySessionStruct.tenantName, forKeyPath: "tenantName")
        setValue(safeEntrySessionStruct.postalCode, forKeyPath: "postalCode")
        setValue(safeEntrySessionStruct.address, forKeyPath: "address")
        setValue(safeEntrySessionStruct.checkInDate, forKeyPath: "checkInDate")
        setValue(safeEntrySessionStruct.checkOutDate, forKeyPath: "checkOutDate")
        setValue(safeEntrySessionStruct.groupIDs, forKeyPath: "groupIDs")
    }

    // MARK: - Encodable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(venueId, forKey: .venueId)
        try container.encode(venueName, forKey: .venueId)
        try container.encode(tenantId, forKey: .tenantId)
        try container.encode(tenantName, forKey: .tenantName)
        try container.encode(postalCode, forKey: .postalCode)
        try container.encode(address, forKey: .address)
        try container.encode(Int(checkInDate!.timeIntervalSince1970), forKey: .checkInDate)
        try container.encode(Int(checkOutDate!.timeIntervalSince1970), forKey: .checkOutDate)
        try container.encode(groupIDs, forKey: .groupIDs)
    }

    func loadVenueOrCreateIfNotExist() {
        if venue == nil {
            venue = (try? managedObjectContext?.fetch(Venue.fetchRequest(by: self)))?.first ?? Venue(session: self)
            try? managedObjectContext?.save()
        }
    }
}
