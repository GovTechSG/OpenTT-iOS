//
//  RecordsViewController.swift
//  OpenTraceTogether

import UIKit
import SafariServices
import CoreData

@objc protocol HistoryRecordDataSource {
    func availableDates() -> [Date]
    func tableView(tableView: UITableView, cellForDate date: Date, row: Int, expanded: Bool) -> UITableViewCell
    @objc optional func numberOfRows(for date: Date) -> Int
    @objc optional func isExpandable(for date: Date, row: Int) -> Bool
    @objc optional func viewForHeader(tableView: UITableView) -> UITableViewCell?
    @objc optional func viewForFooter(tableView: UITableView) -> UITableViewCell?
}

/// A container to display data given by HistoryBluetoothController, HistorySafeEntryController, and HistoryExposureController
class HistoryRecordsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    class SectionData {
        var date: Date?
        var rows: [RowData] = []
    }

    class RowData {
        var dataSource: HistoryRecordDataSource!
        var date: Date!
        var cell: UITableViewCell!
        var index = 0

        init(cell: UITableViewCell) {
            self.cell = cell
        }

        init(dataSource: HistoryRecordDataSource, date: Date, index: Int) {
            self.dataSource = dataSource
            self.date = date
            self.index = index
        }
    }

    @IBOutlet var tableView: UITableView!
    @IBOutlet var noRecordsView: UIView!

    var showAllRecords = true
    var sections: [SectionData] = []
    var selectedIndexPath: IndexPath?
    @IBOutlet var  activityIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: ExposureCardStateUpdatedNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
    }

    deinit {
        HistorySafeEntryController.shared.recordsDelegate = nil
    }

    @objc func reloadData() {
        let dataSources: [HistoryRecordDataSource] = showAllRecords ?
            [HistoryBluetoothController.shared, HistorySafeEntryController.shared, HistoryExposureController.shared] :
            [HistoryExposureController.shared]
        HistorySafeEntryController.shared.recordsDelegate = self
        sections = []

        dataSources.forEach { (dataSource) in
            dataSource.availableDates().forEach { (date) in
                let dayOfDate = Calendar.appCalendar.startOfDay(for: date)
                var section: SectionData! = sections.first(where: { $0.date == dayOfDate })
                if (section == nil) {
                    section = SectionData()
                    section.date = dayOfDate
                    sections.append(section)
                }
                (0..<(dataSource.numberOfRows?(for: date) ?? 1)).forEach { (index) in
                    let row = RowData(dataSource: dataSource, date: date, index: index)
                    section.rows.append(row)
                }
            }
        }

        sections.sort { $0.date! > $1.date! }

        if sections.count == 0 {
            noRecordsView.isHidden = false
            self.view.bringSubviewToFront(noRecordsView)
            tableView.reloadData()
            return
        }
        noRecordsView.isHidden = true
        self.view.bringSubviewToFront(tableView)
        self.view.bringSubviewToFront(activityIndicator)

        if let headerCell = dataSources[0].viewForHeader?(tableView: tableView) {
            let headerSection = SectionData()
            headerSection.rows.append(RowData(cell: headerCell))
            sections.insert(headerSection, at: 0)
        }

        if let footerCell = dataSources[0].viewForFooter?(tableView: tableView) {
            let footerSection = SectionData()
            footerSection.rows.append(RowData(cell: footerCell))
            sections.append(footerSection)
        }
        tableView.reloadData()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let date = sections[section].date, !sections[section].rows.isEmpty else {
            return nil
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, d MMM"
        dateFormatter.locale = Locale(identifier: "en_SG")

        let cell = tableView.dequeueReusableCell(withIdentifier: "SectionHeaderCell") as! HistoryCell
        cell.titleLabel?.text = dateFormatter.string(from: date)
        return cell.contentView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard sections[section].date != nil, !sections[section].rows.isEmpty else {
            return 0
        }
        return 25
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]
        let expanded = selectedIndexPath == indexPath
        return row.cell ?? row.dataSource.tableView(tableView: tableView, cellForDate: row.date, row: row.index, expanded: expanded)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = sections[indexPath.section].rows[indexPath.row]
        let expandable = row.dataSource?.isExpandable?(for: row.date, row: row.index) ?? false

        if expandable {
            if (selectedIndexPath == nil) {
                selectedIndexPath = indexPath
                tableView.reloadRows(at: [indexPath], with: .automatic)
            } else if selectedIndexPath == indexPath {
                selectedIndexPath = nil
                tableView.reloadRows(at: [indexPath], with: .automatic)
            } else {
                let prevIndexPath = selectedIndexPath!
                selectedIndexPath = indexPath
                tableView.reloadRows(at: [prevIndexPath, indexPath], with: .automatic)
            }
        }
    }

    //TODO - Refactor links

    @IBAction func checkForSymptomsBtnPressed(_ sender: UIButton) {
        AnalyticManager.logEvent(eventName: "se_tap_check_symptoms", param: ["position": "history_page"])

        let vc = SFSafariViewController(url: URL(string: "https://sgcovidcheck.gov.sg/")!)
        present(vc, animated: true)
    }

    @IBAction func gotoPossibleExposuresQuestionMarkInfo(_ sender: Any) {
        let vc = SFSafariViewController(url: URL(string: "https://support.tracetogether.gov.sg/hc/en-sg/sections/360007409114-If-you-had-possible-exposure-to-COVID-19")!)
        present(vc, animated: true)
    }

    func invokeCheckOutAPI(_ session: SafeEntrySession, completion: @escaping (_ success: Bool) -> Void) {
        activityIndicator.startAnimating()
        //Handle internet
        if !InternetConnectionManager.isConnectedToNetwork() {
            let retryAction = UIAlertAction(title: NSLocalizedString("Retry", comment: "Retry"), style: .default, handler: { _ in
                self.invokeCheckOutAPI(session, completion: completion)
            })
            SafeEntryUtils.displayErrorAlertNoInternetController(vc: self, customErrMsgTitle: NSLocalizedString("UnableToCheckOut", comment: "Unable to check out"), withCustomRetryAction: retryAction)
            activityIndicator.stopAnimating()
            return
        }

        let unmaskedGroupIDs = (try? SecureStore.getUnmaskedIDs(maskedIDs: session.groupIDs ?? [])) ?? []
            
        // Fire Check Out API - PLEASE CHECK SAFEENTRYACTIONTYPE is correct
        Services.safeEntryAPI.postSEEntry(safeEntryTenant: SafeEntryTenant(fromSafeSentrySession: session), groupIDs: unmaskedGroupIDs, actionType: SafeEntryActionType.checkout.rawValue) {[weak session] (responseDict, error) in
            //Handle error
            self.activityIndicator.stopAnimating()
            guard let responseDict = responseDict else {
                LogMessage.create(type: .Error, title: #function, details: "postSEEntry error: \(error?.localizedDescription ?? "Null")")
                SafeEntryUtils.displayErrorAlertController(vc: self, customErrMsgTitle: NSLocalizedString("SafeEntryTemporarilyUnavailableTitle", comment: "SafeEntry QR is temporarily unavailable"), customErrMsg: NSLocalizedString("SafeEntryOtherMethodsMessage", comment: "Consider using other methods to check in/out"))
                completion(false)
                return
            }

            if responseDict["status"] == "SUCCESS" {
                guard let validTimestamp = responseDict["timeStamp"] else { return }
                guard let currentCheckOutDate = SafeEntryUtils.convertRemoteTimestampToDateObject(dateString: validTimestamp) else { return }
                session?.setValue(currentCheckOutDate, forKey: "checkOutDate")

                do {
                    try Services.database.context.save()
                } catch {
                    print("Could not update SafeEntrySession. \(error)")
                    completion(false)
                    return
                }
                completion(true)
                return
            }
            LogMessage.create(type: .Error, title: #function, details: "postSEEntry. there is an error but no Error object")
        }
    }

}
