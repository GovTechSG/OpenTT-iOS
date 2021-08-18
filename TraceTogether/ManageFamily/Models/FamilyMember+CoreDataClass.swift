//
//  FamilyMember+CoreDataClass.swift
//  OpenTraceTogether

import Foundation
import CoreData

@objc(FamilyMember)
public class FamilyMember: NSManagedObject {

}

struct FamilyMemberRef: Codable {
    var dateSortDescriptor: Date?
    var familyMemberImage: String?
    var familyMemberName: String?
    var familyMemberNRIC: String?
    
    init() {
    }
    
    init(from familyMember: FamilyMember) {
        dateSortDescriptor = familyMember.dateSortDescriptor
        familyMemberImage = familyMember.familyMemberImage
        familyMemberName = familyMember.familyMemberName
        familyMemberNRIC = familyMember.familyMemberNRIC
    }
}
