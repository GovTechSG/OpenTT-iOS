//
//  ExposureModel.swift
//  OpenTraceTogether

import UIKit

class ResponseModel<T: Codable>: Codable {
    class Result: Codable {
        var data: T?
    }
    var result: Result?
}

class ExposureModel: Codable {
    class SafeEntry: Codable {
        var checkin: Session?
        var location: Location?
        var checkout: Session?

        //compare checkInDate & postalCode
        func isEqual(with session: SafeEntrySession) -> Bool {
            guard let postalCode = location?.postalCode,
                let checkInDate = checkin?.time,
                let sessionCheckInDate = session.checkInDate,
                let sessionPostalCode = session.postalCode else {
                return false
            }
            //compare date can false even just a millisecond, better check if the interval is less than a second
            return sessionPostalCode == postalCode && abs(sessionCheckInDate.timeIntervalSince(checkInDate)) < 1
        }
    }

    class Hotspot: Codable {
        var timeWindow: TimeWindow?
        var location: Location?
        var matchId: String?
    }

    class Session: Codable {
        var id: String?
        var time: Date?
        var type: String?
    }

    class Location: Codable {
        var address: String?
        var postalCode: String?
        var description: String?
    }

    class TimeWindow: Codable {
        var start: Date?
        var end: Date?
    }

    var safeentry: SafeEntry?
    var hotspots: [Hotspot]?
    var uinfin: String?

    lazy var id: Date! = safeentry?.checkin?.time ?? Date()
}
