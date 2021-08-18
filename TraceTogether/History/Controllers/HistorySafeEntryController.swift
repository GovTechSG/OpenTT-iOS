//
//  HistorySafeEntryController.swift
//  OpenTraceTogether

import UIKit
import CoreData

class HistorySafeEntryController: NSObject, HistoryRecordDataSource {

    static var shared = HistorySafeEntryController()
    var sessions: [SafeEntrySession] = []
    var tableView: UITableView!
    weak var recordsDelegate: HistoryRecordsViewController?

    func availableDates() -> [Date] {
        sessions = retrieveSafeEntrySessions() ?? []

        //If backend exposures are also recorded as core data sessions then only consider the backend exposures.
        HistoryExposureController.shared.exposures.forEach { (exposure) -> Void in
            if let exposureSE = exposure.safeentry,
                let index = sessions.firstIndex(where: { exposureSE.isEqual(with: $0) }) {
                sessions.remove(at: index)
            }
        }
        return sessions.map { $0.checkInDate! }
    }

    func tableView(tableView: UITableView, cellForDate date: Date, row: Int, expanded: Bool) -> UITableViewCell {
        self.tableView = tableView

        let session = sessions.first(where: { $0.checkInDate == date })!
        session.loadVenueOrCreateIfNotExist()

        let qrCell = tableView.dequeueReusableCell(withIdentifier: "QRCell") as! HistoryCell
        qrCell.titleLabel?.text = retrieveQrCellLocationDisplayText(session)
        qrCell.set(checkInDate: session.checkInDate, checkOutDate: session.checkOutDate)

        let favButton = qrCell.customAccessoryView as! UIButton
        favButton.tag = sessions.firstIndex(of: session)!
        favButton.isSelected = session.venue!.isFavourite
        if favButton.allTargets.isEmpty {
            favButton.addTarget(self, action: #selector(toggleFavorite(_:)), for: .touchUpInside)
        }

        favButton.accessibilityTraits = [.staticText, .button]
        if favButton.isSelected {
            favButton.accessibilityLabel = NSLocalizedString("RemoveFav", comment: "Remove this place from your favourites")
        } else {
            favButton.accessibilityLabel = NSLocalizedString("AddFav", comment: "Add this place to your favourites")
        }

        if let checkOutButton = qrCell.checkOutButton {
            checkOutButton.tag = sessions.firstIndex(of: session)!
            let oneDayAgo = Calendar.appCalendar.date(byAdding: .hour, value: SafeEntryConfig.TTLHours, to: Date())!
            if session.checkOutDate == nil, session.checkInDate! > oneDayAgo {
                if checkOutButton.allTargets.isEmpty {
                    checkOutButton.addTarget(self, action: #selector(checkOutSession(_:)), for: .touchUpInside)
                }
                qrCell.set(checkInDate: session.checkInDate, checkOutDate: session.checkOutDate, showCheckoutOption: true)
            }
        }

        return qrCell
    }

    @objc func checkOutSession(_ checkOutButton: UIButton) {
        recordsDelegate?.invokeCheckOutAPI(sessions[checkOutButton.tag], completion: { (_) in
            self.tableView.reloadRows(at: self.tableView.indexPathsForVisibleRows!, with: .none)
        })
    }

    @objc func toggleFavorite(_ favButton: UIButton) {
        sessions[favButton.tag].venue!.toggleFavouriteAndSave()
        tableView.reloadRows(at: tableView.indexPathsForVisibleRows!, with: .none)
    }

}

extension HistorySafeEntryController: NSFetchedResultsControllerDelegate {

    func retrieveSafeEntrySessions() -> [SafeEntrySession]? {
        let managedContext = Services.database.context
        let checkInFetchRequest: NSFetchRequest<SafeEntrySession> = SafeEntrySession.fetchRequestForHistoryFromDateOfRegistration()
        return try? Services.database.context.fetch(checkInFetchRequest)
    }

    func retrieveQrCellLocationDisplayText(_ session: SafeEntrySession) -> String {
        if session.tenantName == "" || session.tenantName == nil {
            return session.venueName!.uppercased()
        } else {
            return "\(session.tenantName!.uppercased()) (\(session.venueName!.uppercased()))"
        }
    }
}
