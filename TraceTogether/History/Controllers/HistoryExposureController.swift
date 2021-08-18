//
//  ExposureController.swift
//  OpenTraceTogether

import UIKit
import Firebase

enum ExposuresFetchError: String {
    case noInternet = "NoInternet"
    case parsingError = "Unable to serialize data"
}

var ExposureCardStateUpdatedNotification = NSNotification.Name("ExposureCardStateUpdatedNotification")

class HistoryExposureController: HistoryRecordDataSource {

    static var shared = HistoryExposureController()
    var currentExposureCardState: ExposureCardStates = .loading {
        didSet {
            NotificationCenter.default.post(name: ExposureCardStateUpdatedNotification, object: nil, userInfo: nil)
        }
    }

    var exposures: [ExposureModel] = [] {
        didSet {
            saveExposuresToDefaults(exposures)
        }
    }

    var lastUpdated: Date? {
        didSet {
            HistoryExposureController.exposuresLastUpdated = lastUpdated
        }
    }

    static func exposuresHaveExpired() -> Bool {
        let now = Date()
        let exposureTTL = TimeInterval(SafeEntryConfig.ExposureTTL)

        if let exposuresLastUpdated = HistoryExposureController.exposuresLastUpdated {
            guard now > (exposuresLastUpdated + exposureTTL) else {
                return false
            }
        }
        return true
    }

    func fetchData(_ completionBlock: @escaping (String?) -> Void) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970

        if HistoryExposureController.exposuresHaveExpired() {
            if !InternetConnectionManager.isConnectedToNetwork() {
                self.exposures = []
                completionBlock(ExposuresFetchError.noInternet.rawValue)
                return
            }
            SafeEntryAPIs.getSESelfCheck {[weak self] (records, error) in
                if error != nil {
                    LogMessage.create(type: .Error, title: #function, details: "getSESelfCheck API error \(error!.localizedDescription)")
                    completionBlock(error?.localizedDescription)
                }

                guard let records = records, let data = try? JSONSerialization.data(withJSONObject: records, options: []) else {
                    LogMessage.create(type: .Error, title: #function, details: "Parsing error")
                    completionBlock(ExposuresFetchError.parsingError.rawValue)
                    return
                }

                if let models = (try? decoder.decode([ExposureModel].self, from: data)) {
                    self?.exposures = models
                    self?.lastUpdated = Date()
                    completionBlock(nil)
                }
            }
        } else {
            if let exposures = self.getExposuresFromDefaults() {
                self.exposures = exposures
                completionBlock(nil)
            }
        }
    }

    func saveExposuresToDefaults(_ exposures: [ExposureModel]) {
        do {
            try UserDefaults.standard.setObject(exposures, forKey: "exposureModels")
        } catch {
            print(error.localizedDescription)
        }
    }

    func getExposuresFromDefaults() -> [ExposureModel]? {
        do {
            return try UserDefaults.standard.getObject(forKey: "exposureModels", castTo: [ExposureModel].self)
        } catch {
            print(error.localizedDescription)
        }
        return nil
    }

    static var exposuresLastUpdated: Date? {
        get {
            return UserDefaults.standard.object(forKey: "exposuresLastUpdated") as? Date
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "exposuresLastUpdated")
        }
    }

    func availableDates() -> [Date] {
        return exposures.map { $0.id }
    }

    func isExpandable(for date: Date, row: Int) -> Bool {
        return true
    }

    func viewForHeader(tableView: UITableView) -> UITableViewCell? {
        return tableView.dequeueReusableCell(withIdentifier: "ExposureHeaderCell")!
    }

    func viewForFooter(tableView: UITableView) -> UITableViewCell? {
        guard let lastUpdated = lastUpdated else {
            return nil
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        formatter.locale = Locale(identifier: "en_SG")

        let cell = tableView.dequeueReusableCell(withIdentifier: "LastUpdatedCell") as! HistoryCell
        cell.titleLabel?.text = NSLocalizedString("LastUpdated", comment: "Last Updated") + " \(formatter.string(from: lastUpdated))"

        return cell
    }

    func tableView(tableView: UITableView, cellForDate date: Date, row: Int, expanded: Bool) -> UITableViewCell {
        let exposure = exposures.first(where: { $0.id == date })!

        let cell = tableView.dequeueReusableCell(withIdentifier: "ExposureCell") as! HistoryCell
        cell.titleLabel?.text = exposure.safeentry?.location?.description?.uppercased()
        cell.set(checkInDate: exposure.safeentry?.checkin?.time, checkOutDate: exposure.safeentry?.checkout?.time)

        cell.customAccessoryView?.transform = CGAffineTransform.identity
        cell.stackView?.subviews.forEach({ (subViews) in
            subViews.removeFromSuperview()
        })

        if expanded {
            let tapToSeeDetails = NSLocalizedString("TapToCloseDetails", comment: "Tap To close Details")
            if let locationDesc = exposure.safeentry?.location?.description {
                cell.titleLabel?.accessibilityLabel = "\(locationDesc). \(tapToSeeDetails)"
            }
        } else {
            let tapToSeeDetails = NSLocalizedString("TapToSeeDetails", comment: "Tap To See Details")
            if let locationDesc = exposure.safeentry?.location?.description {
                cell.titleLabel?.accessibilityLabel = "\(locationDesc). \(tapToSeeDetails)"
            }
        }

        guard expanded else {
            return cell
        }

        let titleCell = tableView.dequeueReusableCell(withIdentifier: "ExposureTitleCell") as! HistoryCell

        titleCell.titleLabel?.text = NSLocalizedString("CovidVisited", comment: "A COVID-19 case visited") + " \(exposure.hotspots?[0].location?.address ?? "No address found"):"
        cell.stackView?.addArrangedSubview(titleCell.contentView)
        exposure.hotspots?.forEach({ (hotspot) in
            let venueCell = tableView.dequeueReusableCell(withIdentifier: "ExposureVenueCell") as! HistoryCell
            venueCell.titleLabel?.text = hotspot.location?.description?.uppercased()
            venueCell.set(checkInDate: hotspot.timeWindow?.start, checkOutDate: hotspot.timeWindow?.end)
            cell.stackView?.addArrangedSubview(venueCell.contentView)
        })

        let locationPostalCodeString = NSLocalizedString("LocationPostalCode", comment: "Locations are matched by postal code.")

        if exposure.safeentry?.checkout == nil {
            let noteCell = tableView.dequeueReusableCell(withIdentifier: "ExposureNoteCell") as! HistoryCell
            noteCell.titleLabel?.text = locationPostalCodeString + " \(noteCell.titleLabel?.text ?? "")"
            cell.stackView?.addArrangedSubview(noteCell.contentView)
        } else {
            let noteCell = tableView.dequeueReusableCell(withIdentifier: "ExposureNoteCell") as! HistoryCell
            noteCell.titleLabel?.text = locationPostalCodeString
            cell.stackView?.addArrangedSubview(noteCell.contentView)
        }
        cell.customAccessoryView?.transform = CGAffineTransform(rotationAngle: -CGFloat.pi/2)
        cell.layoutIfNeeded()

        return cell
    }
}
