//
//  SafeEntryTenantModel.swift
//  OpenTraceTogether

import Foundation
import CoreData

struct SafeEntryTenant: Codable {

    var venueName: String?
    var venueId: String?
    var tenantId: String?
    var tenantName: String?
    var postalCode: String?
    var address: String?

    init(tenantDict: [String: String?]?) {
        self.venueName = tenantDict?["venueName"] ?? ""
        self.venueId = tenantDict?["venueId"] ?? ""
        self.tenantId = tenantDict?["tenantId"] ?? ""
        self.tenantName = tenantDict?["tenantName"] ?? ""
        self.postalCode = tenantDict?["postalCode"] ?? ""
        self.address = tenantDict?["address"] ?? ""
    }

    init(fromSafeSentrySession SESession: SafeEntrySession?) {
        self.venueName = SESession?.venueName
        self.venueId = SESession?.venueId
        self.tenantId = SESession?.tenantId
        self.tenantName = SESession?.tenantName
        self.postalCode = SESession?.postalCode
        self.address = SESession?.address
    }

    init(fromVenue venue: Venue) {
        self.venueName = venue.name
        self.venueId = venue.id
        self.tenantName = venue.tenantName
        self.tenantId = venue.tenantId
        self.address = venue.address
        self.postalCode = venue.postalCode
    }
}

struct SafeEntrySessionObject: Codable {

    var safeEntryTenant: SafeEntryTenant
    var checkInTimeStamp: Date?
    var checkOutTimeStamp: Date?

    init(safeEntryTenant: SafeEntryTenant, checkInTimeStamp: String?, checkOutTimeStamp: String? ) {
        self.safeEntryTenant = safeEntryTenant
        self.checkInTimeStamp = SafeEntryUtils.convertRemoteTimestampToDateObject(dateString: checkInTimeStamp)
        self.checkOutTimeStamp = SafeEntryUtils.convertRemoteTimestampToDateObject(dateString: checkOutTimeStamp)
    }

    public mutating func updateCheckInTimeStamp(checkInTimeStamp: String?) {
        self.checkInTimeStamp = SafeEntryUtils.convertRemoteTimestampToDateObject(dateString: checkInTimeStamp)
    }

    public mutating func updateCheckOutTimeStamp(checkOutTimeStamp: String?) {
        self.checkOutTimeStamp = SafeEntryUtils.convertRemoteTimestampToDateObject(dateString: checkOutTimeStamp)
    }

}
