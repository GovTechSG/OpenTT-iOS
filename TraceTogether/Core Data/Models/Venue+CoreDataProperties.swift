//
//  Venue+CoreDataProperties.swift
//  OpenTraceTogether

import Foundation
import CoreData

extension Venue {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Venue> {
        return NSFetchRequest<Venue>(entityName: "Venue")
    }

    @nonobjc public class func fetchRequestByFavouritedOnly() -> NSFetchRequest<Venue> {
        let fetchRequest = NSFetchRequest<Venue>(entityName: "Venue")
        fetchRequest.predicate = NSPredicate(format: "isFavourite == true")
        let sortByTenantName = NSSortDescriptor(key: "tenantName", ascending: true)
        let sortByName = NSSortDescriptor(key: "name", ascending: true)
        fetchRequest.sortDescriptors = [sortByName, sortByTenantName]
        return fetchRequest
    }

    @nonobjc public class func fetchRequest(by session: SafeEntrySession) -> NSFetchRequest<Venue> {
        let fetchRequest = NSFetchRequest<Venue>(entityName: "Venue")
        fetchRequest.predicate = NSPredicate(format: "id == %@ and tenantId == %@", session.venueId!, session.tenantId ?? NSNull())
        fetchRequest.fetchLimit = 1
        return fetchRequest
    }

    @nonobjc class func fetchRequestForSessionRecord(_ sessionRecord: SafeEntrySessionRecord) -> NSFetchRequest<Venue> {
       let fetchRequest = NSFetchRequest<Venue>(entityName: "Venue")
       fetchRequest.predicate = NSPredicate(format: "id == %@ and tenantId == %@", sessionRecord.venueId!, sessionRecord.tenantId ?? NSNull())
       fetchRequest.fetchLimit = 1
       return fetchRequest
   }

    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var tenantId: String?
    @NSManaged public var tenantName: String?
    @NSManaged public var address: String?
    @NSManaged public var postalCode: String?
    @NSManaged public var isFavourite: Bool

    convenience init(session: SafeEntrySession) {
        let context = session.managedObjectContext!
        let entity = NSEntityDescription.entity(forEntityName: "Venue", in: context)!
        self.init(entity: entity, insertInto: context)
        id = session.venueId
        name = session.venueName
        tenantId = session.tenantId
        tenantName = session.tenantName
        address = session.address
        postalCode = session.postalCode
    }

    func toggleFavouriteAndSave() {
        isFavourite.toggle()
        try? managedObjectContext?.save()
    }

    func setFavouriteAndSave(_ state: Bool) {
        isFavourite = state
        try? managedObjectContext?.save()
    }
}
