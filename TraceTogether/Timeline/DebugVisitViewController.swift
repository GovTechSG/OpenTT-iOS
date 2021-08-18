//
//  DebugVisitViewController.swift
//  OpenTraceTogether

import Foundation
import CoreData
import MapKit
import UIKit

final class DebugEpisodeViewController: UIViewController {
    @IBOutlet weak var visitTableView: UITableView!

    var fetchedResultsController: NSFetchedResultsController<Visit>?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchVisits()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        visitTableView.dataSource = self
        visitTableView.register(UITableViewCell.self,
                              forCellReuseIdentifier: "VisitCell")
    }

    func fetchVisits() {
        let sortByDate = NSSortDescriptor(key: "startDate", ascending: false)
        fetchedResultsController = DatabaseManager.shared().getFetchedResultsController(Visit.self, with: nil, with: sortByDate, prefetchKeyPaths: nil, delegate: self)
        do {
            try fetchedResultsController?.performFetch()
            let visits = fetchedResultsController?.fetchedObjects
        } catch let error as NSError {
            print("Could not perform fetch. \(error), \(error.userInfo)")
        }
    }

    @IBAction func onExitBtnTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func onTapClearDataButton(_ sender: Any) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<Visit>(entityName: "Visit")
        fetchRequest.includesPropertyValues = false
        do {
            let visits = try managedContext.fetch(fetchRequest)
            for visit in visits {
                managedContext.delete(visit)
            }
            try managedContext.save()
        } catch {
            print("Could not perform delete. \(error)")
        }
    }
}

extension DebugEpisodeViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sections = fetchedResultsController?.sections else {
            return 0
        }
        let sectionInfo = sections[section]

        return sectionInfo.numberOfObjects
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "VisitCell", for: indexPath)
        configureCell(cell, at: indexPath)
        return cell
    }

    func configureCell(_ cell: UITableViewCell, at indexPath: IndexPath) {
        guard let visit = fetchedResultsController?.object(at: indexPath) else {
            return
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .medium
        dateFormatter.timeZone = TimeZone.current

        let startDatetime = visit.startDate
        let startTimeString = "\(startDatetime == nil ? "<NONE>" : dateFormatter.string(from: startDatetime!))"

        let endDatetime = visit.endDate
        let endTimeString = "\(endDatetime == nil ? "<NONE>" : dateFormatter.string(from: endDatetime!))"

        cell.textLabel?.text = """

        Title: \(visit.title ?? "<NONE>"),
        Lat: \(visit.lat), Long: \(visit.long),
        startDate: \(startTimeString),
        endDate: \(endTimeString)
        """
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.font = UIFont.systemFont(ofSize: 11)

    }
}

extension DebugEpisodeViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        visitTableView.beginUpdates()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {

        switch type {
        case .insert:
            if let indexPath = newIndexPath {
                visitTableView.insertRows(at: [indexPath], with: .fade)
            }
            break
        case .delete:
            if let indexPath = indexPath {
                visitTableView.deleteRows(at: [indexPath], with: .fade)
            }
            break
        case .update:
            if let indexPath = indexPath, let cell = visitTableView.cellForRow(at: indexPath) {
                configureCell(cell, at: indexPath)
            }
            break
        case .move:
            if let indexPath = indexPath {
                visitTableView.deleteRows(at: [indexPath], with: .fade)
            }
            if let newIndexPath = newIndexPath {
                visitTableView.insertRows(at: [newIndexPath], with: .fade)
            }
            break
        default:
            break
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        visitTableView.endUpdates()
    }
}
