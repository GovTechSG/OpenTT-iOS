//
//  HistoryBluetoothController.swift
//  OpenTraceTogether

import UIKit
import CoreData

class HistoryBluetoothController: NSObject, HistoryRecordDataSource {

    static var shared = HistoryBluetoothController()

    func availableDates() -> [Date] {
        let today = Calendar.current.startOfDay(for: Date())
        let fourteenDaysAgo = (Calendar.current.date(byAdding: .day, value: SafeEntryConfig.SEHistoryDays, to: today)!)
        var endDate = fourteenDaysAgo
        if dateOfRegistration != nil {
            endDate = dateOfRegistration! < fourteenDaysAgo ?  fourteenDaysAgo : dateOfRegistration!
        }
        let components = Calendar.current.dateComponents([.day], from: today, to: endDate)
        #if DEBUG
        print("today:", today, "\n dateOfRegistration:", dateOfRegistration ?? "Null", "\n fourteenDaysAgo:", fourteenDaysAgo, "\n endDate:", endDate)
        #endif
        var availableDates: [Date] = []
        for n in stride(from: components.day!, to: 0, by: 1) {
            availableDates.append(Calendar.current.date(byAdding: .day, value: n, to: today)!)
        }
        return availableDates
    }

    func viewForHeader(tableView: UITableView) -> UITableViewCell? {
        return tableView.dequeueReusableCell(withIdentifier: "AllRecordsHeaderCell")!
    }

    func tableView(tableView: UITableView, cellForDate date: Date, row: Int, expanded: Bool) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BluetoothCell") as! HistoryCell
        cell.detailLabel?.text = getEncounterCountLabel(for: date)
        return cell
    }

    func getEncounterCountLabel(for date: Date) -> String {
        let encounterCount = Services.encounter.getTotalPerDay(date)
        if encounterCount == 0 {
            return String(format: NSLocalizedString("NumOfExchangesTraceTogetherHistory", comment: "%@ Bluetooth exchanges"), "0")
        }
        let formattedString = encounterCount == 1 ? String(format: NSLocalizedString("NumOfExchangesTraceTogetherHistorySingular", comment: "%@ Bluetooth exchange"), String(encounterCount)) : String(format: NSLocalizedString("NumOfExchangesTraceTogetherHistory", comment: "%@ Bluetooth exchanges"), String(encounterCount))
        return formattedString
    }
}
