//
//  SafeEntryMultipleAddressViewController.swift
//  OpenTraceTogether

import UIKit
import CoreData

class SafeEntryMultipleAddressViewController: SafeEntryBaseViewController {

    @IBOutlet weak var seTableView: UITableView!
    @IBOutlet weak var seTableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var activityLoadingIndicator: UIActivityIndicatorView!

    var tenants: [SafeEntryTenant]? = []
    var selectedTenant: SafeEntryTenant?
    var sessions: [SafeEntrySession] = []

    var seTableViewMaxHeight: CGFloat = 77.0 //Height of one tableView cell

    override func viewDidLoad() {
        super.viewDidLoad()
        selectedGroupIDs = (self.tabBarController as! SafeEntryTabBarController).selectedGroupIDs

        self.navigationController?.setNavigationBarHidden(false, animated: true)
        //Remove bottom line of navBar
        self.navigationController?.navigationBar.setValue(true, forKey: "hidesShadow")
        self.seTableView.register(UINib(nibName: "SECustomTableViewCell", bundle: nil), forCellReuseIdentifier: "seCell")
        self.seTableView.tableFooterView = UIView(frame: .zero)

        //Adjust height of tableview based on dynamic content
        let navHeight = (self.navigationController?.navigationBar.frame.size.height)! + UIApplication.shared.statusBarFrame.size.height
        seTableViewMaxHeight = self.view.frame.size.height - seTableViewMaxHeight - navHeight

        sessions = retrieveSafeEntrySessions() ?? []
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        seTableView.reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AnalyticManager.setScreenName(screenName: "SEMultiTenant", screenClass: "SafeEntryMultipleAddressViewController")
    }

    //Adjust height of tableview based on dynamic content
    override func viewWillLayoutSubviews() {
        DispatchQueue.main.async {
            super.updateViewConstraints()
            self.seTableViewHeightConstraint?.constant = self.seTableView.contentSize.height
            self.seTableViewHeightConstraint?.constant = min(self.seTableViewMaxHeight, self.seTableView.contentSize.height)
            self.view.layoutIfNeeded()
        }
    }

    func retrieveSafeEntrySessions() -> [SafeEntrySession]? {
        guard let tenants =  tenants else {
            return []
        }
        let checkInFetchRequest: NSFetchRequest<SafeEntrySession> = SafeEntrySession.fetchRequestForTenants(tenants: tenants)
        return try? Services.database.context.fetch(checkInFetchRequest)
    }

    @IBAction func returnToPreviousPage(_ sender: UIBarButtonItem) {
        self.navigationController?.popViewController(animated: true)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showCheckInOut" {
            let destinationVC = segue.destination as! CheckInOutViewController
            destinationVC.safeEntryCheckInOutDisplayModel = safeEntryCheckInOutDisplayModel
        }
    }
}

extension SafeEntryMultipleAddressViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tenants!.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "seCell") as! SECustomTableViewCell
        guard let tenants = self.tenants else {
            return cell
        }

        let validSafeEntryTenant = tenants[indexPath.row]
        let tenantName = validSafeEntryTenant.tenantName
        let venueName = validSafeEntryTenant.venueName
        cell.venueNameLabel.text = SafeEntryUtils.formatSETenantVenueDisplay(tenantName, venueName)
        let tapToCheckIn = NSLocalizedString("TapToCheckIn", comment: "Tap to check in to  ")
        cell.venueNameLabel.accessibilityLabel = "\(tapToCheckIn) \(SafeEntryUtils.formatSETenantVenueDisplay(tenantName, venueName))."
        cell.addressLabel.text = tenants[indexPath.row].address

        if let session = sessions.first(where: { $0.venueId == validSafeEntryTenant.venueId && $0.tenantId == validSafeEntryTenant.tenantId }) {
            session.loadVenueOrCreateIfNotExist()

            if session.venue!.isFavourite {
                cell.starButton.setImage(UIImage(named: "favStarSelected"), for: .normal)
                cell.starButton.accessibilityLabel = "This place is added to your Favourites"
            } else {
                cell.starButton.setImage(UIImage(named: "favStarUnselected"), for: .normal)
                cell.starButton.accessibilityLabel = "This place is not yet added to your Favourites"
            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let tenants = self.tenants else {
            return
        }
        selectedTenant = tenants[indexPath.row]
        safeEntryTenant = selectedTenant
        activityLoadingIndicator.startAnimating()
        checkInUserToLocation {[weak self] (_) in
            self?.activityLoadingIndicator.stopAnimating()
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        self.viewWillLayoutSubviews()
    }

}
