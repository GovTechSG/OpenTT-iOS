//
//  ProfileSelectionViewController.swift
//  OpenTraceTogether

import UIKit
import FirebaseAnalytics

enum ProfileType: String {
    case NRIC
    case FIN
    case FINWorkPass
    case FINDependentPass
    case FINStudentPass
    case FINLongTermVisitorPass
    case Visitor
}
class MyTapGesture: UITapGestureRecognizer {
    var section = 0
}

class ProfileSelectionViewController: UIViewController {

    @IBOutlet weak var helpButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    // Localized Strings
    let nricString = "NRIC"
    let fINWorkPassString = "FINWorkPass"
    let fINDepPassString = "FINDepPass"
    let finStudPassString = "FINStudPass"
    let finLTVPString = "FINLTVP"
    let visitSGString = "VisitSG"

    let nricDescString = NSLocalizedString("NRICDesc", comment: "Please have your NRIC or Birth Cert No. ready :)")
    let finWorkPassDescString = NSLocalizedString("FINWorkPassDesc", comment: "Please have your Work Pass card ready :)")
    let finDepPassDescString = NSLocalizedString("FINDepPassDesc", comment: "Please have your Dependent’s Pass card ready :)")
    let finStudPassDescString = NSLocalizedString("FINStudPassDesc", comment: "Please have your Student’s Pass card ready :)")
    let finLTVPDescString = NSLocalizedString("FINLTVPDesc", comment: "Please have your FIN Long Term Visit Pass card ready :)")
    let visitSGDescString = NSLocalizedString("VisitSGDesc", comment: "Please use the Passport that you'll enter Singapore with :)")

    //DataArray
    var sectionTitleArray = [String]()
    var profileImageResourceArray = ["icon_nric", "icon_greenpass", "icon_greenpass", "icon_greenpass", "icon_greenpass", "icon_passport"]
    var profileDescriptionArray = [String]()
    var sectionRowArray =  [0, 0, 0, 0, 0, 0, 0]
    //Var declaration
    var profileType: ProfileType = .NRIC
    var didSelection = false
    var selectedIndex = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        helpButton.accessibilityLabel = NSLocalizedString("Help", comment: "Help")

        sectionTitleArray = [nricString, fINWorkPassString, fINDepPassString, finStudPassString, finLTVPString, visitSGString]
        profileDescriptionArray = [nricDescString, finWorkPassDescString, finDepPassDescString, finStudPassDescString, finLTVPDescString, visitSGDescString]

        tableView?.estimatedRowHeight = 100
        tableView?.rowHeight = UITableView.automaticDimension
        tableView?.sectionHeaderHeight = 70
        tableView?.separatorStyle = .none
        let headerNib = UINib(nibName: "ProfileHeaderView", bundle: Bundle.main)
        tableView.register(headerNib, forHeaderFooterViewReuseIdentifier: "header")
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AnalyticManager.setScreenName(screenName: "OnboardSelectProfile", screenClass: "ProfileSelectionViewController")
    }

    @IBAction func nextButtonClicked(_ sender: Any) {
        LogMessage.create(type: .Info, title: #function, details: ["didSelection": "\(didSelection)"], collectable: true)
        if self.didSelection == true {
            performSegue(withIdentifier: "showNewForm", sender: self.profileType)
        }
    }
    @IBAction func backButtonClicked(_ sender: Any) {
        LogMessage.create(type: .Info, title: #function, collectable: true)
        self.navigationController?.popViewController(animated: true)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        LogMessage.create(type: .Info, title: #function, collectable: true)
        if (segue.identifier == "showNewForm") {
            let destinationVC = segue.destination as! FormRegisterViewController
            destinationVC.profileType = sender as! ProfileType
        }
    }

    func updateSelectionWith(index: Int) {
        switch index {
        case 0:
            self.profileType = .NRIC
        case 1:
            self.profileType = .FINWorkPass
        case 2:
            self.profileType = .FINDependentPass
        case 3:
            self.profileType = .FINStudentPass
        case 4:
            self.profileType = .FINLongTermVisitorPass
        case 5:
            self.profileType = .Visitor
        default:
            //Exception index
            didSelection = false
            self.nextButton.setBackgroundColor(color: UIColor(hexString: "#FF6565"), forState: .normal)
            self.nextButton.setTitleColor(UIColor.white, for: .normal)
        }
    }
}

extension ProfileSelectionViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let profileCell = tableView.dequeueReusableCell(withIdentifier: "ProfileCell", for: indexPath) as! ProfileCell
        let imageResource = self.profileImageResourceArray[indexPath.section]
        let description = self.profileDescriptionArray[indexPath.section]
        profileCell.titleLabel.text = description
        profileCell.iconView.image = UIImage(imageLiteralResourceName: imageResource)
        return profileCell
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionRowArray[section]
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionTitleArray.count
    }
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sectionTitleArray.count
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "header") as! ProfileHeaderView
        let titleString = self.sectionTitleArray[section]
        let tapToSeeDetails = NSLocalizedString("TapToSeeDetails", comment: "Tap To See Details")
        headerView.titleLabel.accessibilityLabel = "\(titleString). \(tapToSeeDetails)"

        if self.didSelection == true {
            if self.selectedIndex == section {
                headerView.setSelected()
                headerView.shadow(height: 1)
                headerView.titleLabel.accessibilityLabel = "\(titleString)"
            } else {
                headerView.setDeselected()
                headerView.removeShadow()
                headerView.titleLabel.accessibilityLabel = "\(titleString). \(tapToSeeDetails)"
            }
        } else {
            if section == 0 {
                headerView.setDefaultSelected()
                headerView.shadow(height: 1)
            } else {
                headerView.setDefaultDeselected()
                headerView.removeShadow()
            }
        }
        headerView.titleLabel.text = NSLocalizedString(titleString, comment: "")
        headerView.accessibilityIdentifier = titleString

        if section == sectionTitleArray.count - 1 {
            headerView.detailsLabel.isHidden = false
            headerView.detailsLabel.text = NSLocalizedString("PassportVerified", comment: "Verified with Singapore’s immigration")
            headerView.titleLabelTopConstraint?.isActive = true
            headerView.titleLabelTopConstraint?.constant = 15.0
            headerView.titleLabelCenterInContainerConstraint?.isActive = false
        } else {
            headerView.detailsLabel.isHidden = true
            headerView.titleLabelTopConstraint?.isActive = false
            headerView.titleLabelCenterInContainerConstraint?.isActive = true
        }

        //Adding tag gesture to handle tap
        let tapRecognizer = MyTapGesture(target: self, action: #selector(handleTap))
        tapRecognizer.section = section
        tapRecognizer.numberOfTapsRequired = 1
        tapRecognizer.numberOfTouchesRequired = 1
        headerView.addGestureRecognizer(tapRecognizer)
        return headerView
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == sectionTitleArray.count - 1 {
            return 90
        }
        return 70
    }
    @objc func handleTap(gestureRecognizer: MyTapGesture) {
        LogMessage.create(type: .Info, title: #function, collectable: true)
        self.selectedIndex  = gestureRecognizer.section
        self.didSelection = true
        self.updateSelectionWith(index: self.selectedIndex)
        self.nextButton.isEnabled = true
        self.nextButton.setBackgroundColor(color: UIColor(hexString: "#FF6565"), forState: .normal)
        self.nextButton.setTitleColor(UIColor.white, for: .normal)
        self.sectionRowArray = [0, 0, 0, 0, 0, 0]
        self.sectionRowArray[gestureRecognizer.section] = 1

        let set: IndexSet =  [0, 1, 2, 3, 4, 5]
        self.tableView.reloadSections(set, with: .fade)
    }
}
