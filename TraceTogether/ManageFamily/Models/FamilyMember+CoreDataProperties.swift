//
//  FamilyMember+CoreDataProperties.swift
//  OpenTraceTogether

import Foundation
import CoreData

extension FamilyMember {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FamilyMember> {
        return NSFetchRequest<FamilyMember>(entityName: "FamilyMember")
    }

    @NSManaged public var dateSortDescriptor: Date?
    @NSManaged public var familyMemberImage: String?
    @NSManaged public var familyMemberName: String?
    @NSManaged public var familyMemberNRIC: String?

}
