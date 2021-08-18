//
//  SEFavouriteListViewController.swift
//  OpenTraceTogether

import UIKit
import CoreData

class SEFavouriteListViewController: SafeEntryBaseViewController {

    @IBOutlet weak var progressView: UIView!
    @IBOutlet weak var checkInToLbl: UILabel!
    @IBOutlet weak var backBtn: UIButton!

    @IBOutlet weak var leadingProgressConstraint: NSLayoutConstraint!
    @IBOutlet weak var trailingProgressConstraint: NSLayoutConstraint!
    @IBOutlet weak var favouriteTableView: UITableView!
    @IBOutlet weak var favSearchBar: UISearchBar!
    @IBOutlet weak var howToUseView: UIView!
    @IBOutlet weak var noSearchResultsFoundView: SEFavouriteNoResultFound!
    @IBOutlet weak var noFavouritesView: UIView!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var declarationClauseView: UIView!

    @IBOutlet var constraintFromTableViewToAgreeLabel: NSLayoutConstraint!
    @IBOutlet var constraintFromTableViewToDeclarationClauseView: NSLayoutConstraint!
    @IBOutlet weak var activityLoadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var checkDeclarationButton: UIButton!

    var searchIsActive: Bool {
        if let searchText = favSearchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines), searchText.isEmpty == false {
            return true
        }
        return false
    }
    var favoriteData = [Venue]()
    var filteredData = [Venue]()

    let messageArray = [NSLocalizedString("seMsg1", comment: "You have no close contact with a confirmed COVID-19 case in the past 14 days *#"), NSLocalizedString("seMsg2", comment: "You're not currently under a Quarantine Order or Stay-Home Notice *"), NSLocalizedString("seMsg3", comment: "You have no fever or flu-like symptoms *"), NSLocalizedString("seMsg4", comment: "You agree to the terms and consent to the collection/use of your information for COVID-19 contact tracing")]

    var groupCheckInFlowToHandleIDTab = Bool()

    override func viewDidLoad() {
        super.viewDidLoad()

        UserDefaults.standard.set(true, forKey: "FavouritesTabVisited")
        self.tabBarController?.viewControllers?[1].tabBarItem.badgeValue = nil

        favSearchBar.delegate = self

        noSearchResultsFoundView.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.favouriteTableView.frame.size.height)

        self.favouriteTableView.register(UINib(nibName: "SECustomFavouriteTableViewCell", bundle: nil), forCellReuseIdentifier: "FavouriteCell")
        self.favouriteTableView.tableFooterView = UIView(frame: .zero)

        //Make terms clickable
        messageTextView.attributedText = makeBulletedAttributedString(stringList: messageArray, font: UIFont.systemFont(ofSize: 14.0), bullet: "-", textColor: UIColor(hexString: "#828282"), bulletColor: UIColor(hexString: "#828282"))

        setupHowToUseAction()
        checkDeclarationButton.accessibilityLabel = "Show Declaration"
        hideDeclarationClause()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)

        favSearchBar.placeholder = NSLocalizedString("SearchFav", comment: "Search from list below")

        //use viewController.hidesBottomBarWhenPushed next time
        tabBarController?.tabBar.isHidden = false

        let checkInFetchRequest: NSFetchRequest<Venue> = Venue.fetchRequestByFavouritedOnly()
        favoriteData = (try? Services.database.context.fetch(checkInFetchRequest)) ?? []

        noFavouritesView.isHidden = !favoriteData.isEmpty
        favouriteTableView.reloadData()

        // Handle Accessibility
        if noFavouritesView.isHidden == false {
            for aView in self.view.subviews {
                if aView != noFavouritesView && aView != backBtn && aView != howToUseView {
                    aView.isAccessibilityElement = false
                    aView.accessibilityElementsHidden = true
                }
            }
        }

        activityLoadingIndicator.stopAnimating()

        if groupCheckInFlowToHandleIDTab {
            leadingProgressConstraint.constant = UIScreen.main.bounds.width/2
        } else {
            leadingProgressConstraint.constant = UIScreen.main.bounds.width/3
            trailingProgressConstraint.constant = UIScreen.main.bounds.width/3
        }
        customiseSearchBar()
    }

    func customiseSearchBar() {
        favSearchBar.layer.borderWidth = 1.0
        favSearchBar.layer.borderColor = UIColor(red: 189.0/255.0, green: 189.0/255.0, blue: 189.0/255.0, alpha: 1.0).cgColor
        favSearchBar.layer.cornerRadius = 4.0
        if #available(iOS 13.0, *) {
            favSearchBar.searchTextField.backgroundColor = UIColor.white
            favSearchBar.searchTextField.font = UIFont.systemFont(ofSize: 16)
        } else {
            favSearchBar.barTintColor = .white
        }
    }

    func setupHowToUseAction() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(goToHelpView))
        tapGestureRecognizer.numberOfTapsRequired = 1
        self.howToUseView.addGestureRecognizer(tapGestureRecognizer)
    }

    @objc func goToHelpView(recognizer: UITapGestureRecognizer) {
        self.showFavoritesInstructions()
    }

    func showFavoritesInstructions() {
        let storyboard = UIStoryboard(name: "SafeEntry", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "QRInstructionsViewController") as! UINavigationController
        vc.modalPresentationStyle = .fullScreen
        vc.modalTransitionStyle = .crossDissolve
        if groupCheckInFlowToHandleIDTab {
            UserDefaults.standard.setValue(true, forKey: "groupCheckInFlowToHandleHowToUse")
        } else {
            UserDefaults.standard.setValue(false, forKey: "groupCheckInFlowToHandleHowToUse")
        }
        self.present(vc, animated: true, completion: nil)
    }

    @IBAction func returnToMainPage(_ sender: UIButton) {
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        self.navigationController?.dismiss(animated: true, completion: nil)
    }

    @IBAction func declarationClauseActionButtonPressed(_ sender: UIButton) {

        sender.isSelected.toggle()
        if sender.isSelected {
            showDeclarationClause()
            checkDeclarationButton.accessibilityLabel = "Hide Declaration"
        } else {
            hideDeclarationClause()
            checkDeclarationButton.accessibilityLabel = "Show Declaration"
        }

    }

    func hideDeclarationClause() {
        declarationClauseView.isHidden = true
        self.constraintFromTableViewToAgreeLabel.constant = 20
        if self.constraintFromTableViewToDeclarationClauseView != nil {
            self.constraintFromTableViewToDeclarationClauseView.isActive = false
        }
        self.constraintFromTableViewToAgreeLabel.isActive = true
    }

    func showDeclarationClause() {
        declarationClauseView.isHidden = false
        self.constraintFromTableViewToDeclarationClauseView.isActive = true
    }

}

extension SEFavouriteListViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(searchIsActive) {
            if filteredData.count == 0 {
                noSearchResultsFoundView.isHidden = false
            } else {
                noSearchResultsFoundView.isHidden = true
            }
            return filteredData.count
        }
        noSearchResultsFoundView.isHidden = true
        return favoriteData.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FavouriteCell", for: indexPath) as! SECustomFavouriteTableViewCell

        if cell.starButton.allTargets.isEmpty {
            cell.starButton.addTarget(self, action: #selector(SEFavouriteListViewController.onStarBtnPressed), for: .touchUpInside)
        }
        cell.starButton.tag = indexPath.row

        let venue = (searchIsActive ? filteredData : favoriteData)[indexPath.row]

        if venue.isFavourite {
            let favSelected = UIImage(named: "favStarSelected")
            cell.starButton.setImage(favSelected, for: .normal)
            cell.starButton.accessibilityLabel = NSLocalizedString("RemoveFav", comment: "Remove this place from your favourites")
        } else {
            let favUnselected = UIImage(named: "favStarUnselected")
            cell.starButton.setImage(favUnselected, for: .normal)
            cell.starButton.accessibilityLabel = NSLocalizedString("AddFav", comment: "Add this place to your favourites")
        }

        print("indexPath.row:\(indexPath.row) favorite:\(favoriteData)" )
        let tenantName = venue.tenantName?.uppercased()
        let venueName = venue.name?.uppercased()
        cell.venueNameLabel.text = SafeEntryUtils.formatSETenantVenueDisplay(tenantName, venueName)
        cell.addressLabel.text = venue.address
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let venue = (searchIsActive ? filteredData : favoriteData)[indexPath.row]
        safeEntryTenant = SafeEntryTenant(fromVenue: venue)
        tableView.deselectRow(at: indexPath, animated: true)
        activityLoadingIndicator.startAnimating()
        checkInUserToLocation {[weak self] (_) in
            self?.activityLoadingIndicator.stopAnimating()
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showCheckInOut" {
            let destinationVC = segue.destination as! CheckInOutViewController
            destinationVC.safeEntryCheckInOutDisplayModel = safeEntryCheckInOutDisplayModel
        }
    }

    @objc func onStarBtnPressed(sender: UIButton) {

        let venue = (searchIsActive ? filteredData : favoriteData)[sender.tag]
        venue.toggleFavouriteAndSave()
        favouriteTableView.reloadData()
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 28.0))
        sectionView.backgroundColor = UIColor(red: 242.0/255.0, green: 242.0/255.0, blue: 242.0/255.0, alpha: 1.0)

        let sectionlabel = UILabel(frame: CGRect(x: 16, y: 4, width: view.frame.size.width, height: 20))
        sectionlabel.font = UIFont.systemFont(ofSize: 14.0, weight: .bold)
        sectionlabel.textColor = UIColor(red: 79.0/255.0, green: 79.0/255.0, blue: 79.0/255.0, alpha: 1.0)
        sectionlabel.text = NSLocalizedString("FavPlace", comment: "YOUR FAVOURITE PLACES")

        sectionView.addSubview(sectionlabel)
        return sectionView
    }

}

extension SEFavouriteListViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty { //when user press clear button
            searchBar.perform(#selector(self.resignFirstResponder), with: nil, afterDelay: 0.1)
        } else {
            filteredData = favoriteData.filter { venue in
                return [venue.name, venue.tenantName, venue.address].contains(where: { str in
                    str?.lowercased().contains(searchText.lowercased()) ?? false}
                )
            }
        }
        favouriteTableView.reloadData()
        updateAccessibility()
    }

    func updateAccessibility() {
        // Handle Accessibility
        if noSearchResultsFoundView.isHidden == false { //search view is shown
            for aView in self.view.subviews {
                if aView != noSearchResultsFoundView && aView != backBtn && aView != howToUseView && aView != checkInToLbl && aView != favSearchBar {
                    aView.isAccessibilityElement = false
                    aView.accessibilityElementsHidden = true
                }
            }
        } else { //search view is hidden
            for aView in self.view.subviews {
                if aView != noSearchResultsFoundView && aView != progressView && aView != noFavouritesView, aView != favSearchBar {
                    aView.isAccessibilityElement = true
                    aView.accessibilityElementsHidden = false
                }
            }
            declarationClauseView.isAccessibilityElement = false
        }
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {

    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
    }

}
