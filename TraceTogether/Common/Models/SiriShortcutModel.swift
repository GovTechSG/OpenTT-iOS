//
//  SiriShortcutModel.swift
//  OpenTraceTogether

import Foundation

class SiriShortcutModel {

    static let kScanQRId = "TTScanQR"
    static let kFavouritesCheckInId = "TTFavouritesCheckIn"
    static let kGroupCheckInId = "TTGroupCheckIn"
    static let kCheckOutId = "TTCheckOut"

    static let allEntities = [
        SiriShortcutModel(id: kScanQRId, title: "SafeEntry Scan QR"),
        SiriShortcutModel(id: kFavouritesCheckInId, title: "SafeEntry Favourites"),
        SiriShortcutModel(id: kGroupCheckInId, title: "SafeEntry Group"),
        SiriShortcutModel(id: kCheckOutId, title: "SafeEntry Check out")
    ]

    var id: String
    var title: String

    init(id: String, title: String) {
        self.id = id
        self.title = title
    }
}
