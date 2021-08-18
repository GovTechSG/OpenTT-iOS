//
//  IEncounterService.swift
//  OpenTraceTogether

import Foundation

struct EncounterTodayHighlight: Equatable {
    /// Total encounter for today
    let total: Int

    /// Minimum total encountered device in the last 5 minutes
    let nearbyLowerRange: Int

    /// Maximum total encountered device in the last 5 minutes
    let nearbyUpperRange: Int
}

protocol EncounterServiceProtocol {

    /// Bluetrace manager can refactor to use these functions
    func addStartScanningMsg(date: Date)
    func add(msg: String, role: String, date: Date)
    func addLite(msg: String, rssi: NSNumber, txPower: NSNumber, date: Date)
    func addStopScanningMsg(date: Date)

    /// For home screen
    func observeTodayHighlight(_ weakRef: AnyObject, callback: @escaping () -> Void)
    func getTodayHighlight() -> EncounterTodayHighlight

    /// For history screen
    func getTotalPerDay(_ date: Date) -> Int

    func removeData25DaysOld()
}
