//
//  SafeEntryCheckInOutDisplayModel.swift
//  OpenTraceTogether

import Foundation

class SafeEntryCheckInOutDisplayModel: NSObject, Codable {

    ///Full address
    var VENUENAME: String = ""
    ///Check in date
    var CHECKINDATE: String = ""
    ///Check out date
    var CHECKINTIME: String = ""
    ///Check in date
    var CHECKOUTDATE: String = ""
    ///Check out date
    var CHECKOUTTIME: String = ""
    ///Check if user viewed checkin pass
    var VIEWEDCHECKINPASS: Bool = false
    ///Check if user viewed checkout pass
    var VIEWEDCHECKOUTPASS: Bool = false
    ///Total number of user's Checking IN/OUT
    var NUMBEROFPERONCHECKING: Int = 1

    var tenantID: String = ""

    var venueID: String = ""
}
