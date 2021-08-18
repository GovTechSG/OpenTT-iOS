//
//  SafeEntrySessionRecord.swift
//  OpenTraceTogether

import Foundation

struct SafeEntrySessionRecord: Encodable {
    var venueId: String?
    var venueName: String?
    var tenantId: String?
    var tenantName: String?
    var postalCode: String?
    var address: String?
    var checkInDate: Date?
    var checkOutDate: Date?
    var groupIDs: [String]?

    init(venueId: String, venueName: String, tenantId: String, postalCode: String, address: String, checkInDate: Date) {
        self.venueId = venueId
        self.venueName = venueName
        self.tenantId = tenantId
        self.tenantName = tenantId
        self.postalCode = postalCode
        self.address = address
        self.checkInDate = checkInDate
        self.checkOutDate = nil
        self.groupIDs = nil
    }

    init(from safeEntryTenant: SafeEntryTenant, checkInDate: Date) {
        self.venueId = safeEntryTenant.venueId
        self.venueName = safeEntryTenant.venueName
        self.tenantId = safeEntryTenant.tenantId
        self.tenantName = safeEntryTenant.tenantName
        self.postalCode = safeEntryTenant.postalCode
        self.address = safeEntryTenant.address
        self.checkInDate = checkInDate
        self.checkOutDate = nil
        self.groupIDs = nil
    }

    init(from safeEntrySession: SafeEntrySession, checkOutDate: Date) {
        self.venueId = safeEntrySession.venueId
        self.venueName = safeEntrySession.venueName
        self.tenantId = safeEntrySession.tenantId
        self.tenantName = safeEntrySession.tenantName
        self.postalCode = safeEntrySession.postalCode
        self.address = safeEntrySession.address
        self.checkInDate = safeEntrySession.checkInDate
        self.checkOutDate = checkOutDate
        self.groupIDs = safeEntrySession.groupIDs
    }
}
