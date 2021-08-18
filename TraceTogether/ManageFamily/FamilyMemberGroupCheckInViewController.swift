//
//  FamilyMemberGroupCheckInViewController.swift
//  OpenTraceTogether

import UIKit
import CoreData

class FamilyMemberGroupCheckInViewController: UIViewController {

    @IBOutlet weak var familyMemberGroupCheckInTableView: UITableView!
    @IBOutlet weak var noFamilyMemberView: NoFamilyMemberView!
    @IBOutlet weak var familyMemberTableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var addAnotherPersonBtn: UIButton!
    @IBOutlet weak var selectAllBtn: UIButton!

    var familyMemberArray = [FamilyMemberRef]()
    var selectedFamilyMembers: Set<String> = []
    var didPresentSafeEntry: (() -> Void)?
    var memberNric = String()
    var selectedRowsIndexPathArray = [IndexPath]()
    var totalMembers = 0

    let familyMemberTableViewMaxHeight: CGFloat = 66.0 //Height of one tableView cell

    override func viewDidLoad() {
        super.viewDidLoad()
        selectedFamilyMembers = []
        familyMemberGroupCheckInTableView.register(UINib(nibName: "FamilyMemberGroupCheckInTableViewCell", bundle: nil), forCellReuseIdentifier: "familyMemberGroupCheckInCell")

        noFamilyMemberView.delegate = self

        addAnotherPersonBtn.contentHorizontalAlignment = .left
        createSelectAllButton()
        selectAllBtn.contentHorizontalAlignment = .right

        //Find Member NRIC to be displayed in familyMemberGroupCheckInTableView first cell
        do {
            let userIdValue = try SecureStore.readCredentials(service: "nricService", accountName: "id").password
            let secureStringId = NricFinMask.maskUserId(userIdValue)
            memberNric = secureStringId
        } catch {
            if let error = error as? SecureStore.KeychainError {
                if #available(iOS 11.3, *) {
                    LogMessage.create(type: .Error, title: #function, details: "KeychainError: \(error.localizedDescription)", debugMessage: "KeychainError: \(error.localizedDescription)")
                } else {
                    LogMessage.create(type: .Error, title: #function, details: "KeychainError: \(error)", debugMessage: "KeychainError: \(error)")
                }
            }
        }
    }

    func createSelectAllButton() {
        selectAllBtn.setAttributedTitle(NSLocalizedString("SelectAll", comment: "Select all"), for: .normal)
        selectAllBtn.setAttributedTitle(NSLocalizedString("UnselectAll", comment: "Unselect all"), for: .selected)
    }

    @IBAction func addAnotherPersonBtnPressed(_ sender: UIButton) {
        addFamilyMemberButtonTapped()
    }

    @IBAction func selectAllBtnPressed(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            for index in 1...familyMemberArray.count {
                print(index)
                let indexPath = IndexPath(row: index, section: 0)
                selectedRowsIndexPathArray.append(indexPath)
                let itemCell = familyMemberGroupCheckInTableView.cellForRow(at: indexPath) as! FamilyMemberGroupCheckInTableViewCell
                itemCell.selectFamilyMemberButton.isSelected = true
                itemCell.familyMemberImageView.alpha = 1.0
                selectedFamilyMembers.insert(familyMemberArray[index-1].familyMemberNRIC!)
                itemCell.selectFamilyMemberButton.accessibilityLabel = NSLocalizedString("CheckedFamilyMember", comment: "Checked, Family member selected")
            }
        } else {
            selectedRowsIndexPathArray.removeAll()
            for index in 1...familyMemberArray.count {
                print(index)
                let indexPath = IndexPath(row: index, section: 0)
                let itemCell = familyMemberGroupCheckInTableView.cellForRow(at: indexPath) as! FamilyMemberGroupCheckInTableViewCell
                itemCell.selectFamilyMemberButton.isSelected = false
                itemCell.familyMemberImageView.alpha = 0.50
                itemCell.selectFamilyMemberButton.accessibilityLabel = NSLocalizedString("UncheckedFamilyMember", comment: "Unchecked, Family member not selected")
            }
            selectedFamilyMembers = []
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.tabBarController?.tabBar.isHidden = true
        fetchData()

        // Handle Accessibility
        if noFamilyMemberView.isHidden == false {
            for aView in self.view.subviews {
                if aView != noFamilyMemberView {
                    aView.isAccessibilityElement = false
                    aView.accessibilityElementsHidden = true
                }
            }
            noFamilyMemberView.isAccessibilityElement = false
        } else {
            for aView in self.view.subviews {
                if aView != noFamilyMemberView {
                    aView.isAccessibilityElement = true
                    aView.accessibilityElementsHidden = false
                }
                if aView is UIScrollView {
                    aView.isAccessibilityElement = false
                }
            }
        }
    }

    //Adjust height of tableview based on dynamic content
    override func viewWillLayoutSubviews() {
        DispatchQueue.main.async {
            super.updateViewConstraints()
            self.familyMemberTableViewHeightConstraint?.constant = self.familyMemberGroupCheckInTableView.contentSize.height
            self.familyMemberTableViewHeightConstraint?.constant = max(self.familyMemberTableViewMaxHeight, self.familyMemberGroupCheckInTableView.contentSize.height)
            self.view.layoutIfNeeded()
        }
    }

    func selectFamilyMember(_ sender: FamilyMemberGroupCheckInTableViewCell) {
        guard let indexPath = familyMemberGroupCheckInTableView.indexPath(for: sender) else { return }
        sender.selectFamilyMemberButton.isSelected = !sender.selectFamilyMemberButton.isSelected
        if sender.selectFamilyMemberButton.isSelected {
            sender.selectFamilyMemberButton.accessibilityLabel = NSLocalizedString("CheckedFamilyMember", comment: "Checked, Family member selected")
            sender.familyMemberImageView.alpha = 1.0
            selectedRowsIndexPathArray.append(indexPath)
            selectedFamilyMembers.insert(familyMemberArray[indexPath.row - 1].familyMemberNRIC!)
            if selectedFamilyMembers.count == familyMemberArray.count {
                if !selectAllBtn.isSelected {
                    selectAllBtn.isSelected = !selectAllBtn.isSelected
                }
            }
        } else {
            sender.selectFamilyMemberButton.accessibilityLabel = NSLocalizedString("UncheckedFamilyMember", comment: "Unchecked, Family member not selected")
            sender.familyMemberImageView.alpha = 0.5
            if let index = selectedRowsIndexPathArray.firstIndex(of: indexPath) {
                selectedRowsIndexPathArray.remove(at: index)
            }
            selectedFamilyMembers.remove(familyMemberArray[indexPath.row - 1].familyMemberNRIC!)
            if selectedFamilyMembers.count == 0 || selectedFamilyMembers.count < familyMemberArray.count {
                if selectAllBtn.isSelected {
                    selectAllBtn.isSelected = !selectAllBtn.isSelected
                }
            }
        }
    }

    func fetchData() {
        print("Fetching Family members..")
        
        let fetchRequest: NSFetchRequest<FamilyMember> = FamilyMember.fetchRequest()
        do {
            let familyMembers = try SecureStore.getAllFamilyMembers()
            self.familyMemberArray = familyMembers
            
            //When all checkboxes are selected (button displays unselect all) and new member is added, button text should change to select all
            if selectedFamilyMembers.count < self.familyMemberArray.count {
                if selectAllBtn.isSelected {
                    selectAllBtn.isSelected = !selectAllBtn.isSelected
                }
            }
            //Retain checkbox selection when new member is added
            if self.familyMemberArray.count > totalMembers {
                totalMembers = self.familyMemberArray.count
                for (index, var indexPath) in selectedRowsIndexPathArray.enumerated() {
                    indexPath.row += 1
                    selectedRowsIndexPathArray[index].row = indexPath.row
                }
                self.familyMemberGroupCheckInTableView.reloadData()
            }

            if self.familyMemberArray.count == 0 {
                self.noFamilyMemberView.isHidden = false
                self.title = NSLocalizedString("AddFamilyMember", comment: "Add Family Members")
                self.view.isAccessibilityElement = false
                noFamilyMemberView.isAccessibilityElement = true
            } else {
                self.noFamilyMemberView.isHidden = true
                self.title = NSLocalizedString("SafeEntry", comment: "SafeEntry")
                self.familyMemberGroupCheckInTableView.reloadData()
            }
        } catch {
            print("Fetching data Failed")

        }
    }

    @IBAction func backBtnPressed(_ sender: UIBarButtonItem) {
        self.navigationController?.popViewController(animated: true)
    }

    @IBAction func nextBtnPressed(_ sender: UIButton) {
        allowUserToScanQR()
    }

    func allowUserToScanQR() {
        let storyboard = UIStoryboard(name: "SafeEntry", bundle: nil)

        let tabbarVC = storyboard.instantiateViewController(withIdentifier: "SafeEntryFlow") as! SafeEntryTabBarController
        tabbarVC.userDelegate = self.navigationController
        let maskedGroupIDs = self.selectedFamilyMembers.map { NricFinMask.maskUserId($0) }
        tabbarVC.selectedGroupIDs = maskedGroupIDs
        tabbarVC.viewControllers?.remove(at: 2)

        let navQRVC = tabbarVC.viewControllers?[0] as! UINavigationController
        if let qrViewTabBarController = navQRVC.topViewController as? QRViewController {
            qrViewTabBarController.groupCheckInFlowToHandleIDTab = true
        }

        let navFavVC = tabbarVC.viewControllers?[1] as! UINavigationController
        if let seFavListVCTabBarController = navFavVC.topViewController as? SEFavouriteListViewController {
            seFavListVCTabBarController.groupCheckInFlowToHandleIDTab = true
        }

        self.present(tabbarVC, animated: false, completion: self.didPresentSafeEntry)
    }

    override func viewWillDisappear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = false
    }
}

extension FamilyMemberGroupCheckInViewController: UITableViewDelegate, UITableViewDataSource, ManageFamilyMemberGroupCheckInDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return familyMemberArray.count + 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "familyMemberGroupCheckInCell", for: indexPath) as! FamilyMemberGroupCheckInTableViewCell

        cell.delegate = self
        if indexPath.row == 0 {
            if let userProfileValue = UserDefaults.standard.string(forKey: "userprofile_name") {
                cell.nicknameLabel.text = userProfileValue + " (YOU)"
            }
            cell.nricFinLabel.text = memberNric
            let image = UIImage(named: "pinkOtter.png")
            cell.familyMemberImageView.image = image
            cell.familyMemberImageView.alpha = 1.0
            cell.selectFamilyMemberButton.isHidden = true
        } else {

            if let nameString = familyMemberArray[indexPath.row - 1].familyMemberName {
                cell.nicknameLabel.text = nameString
            }

            if let nricString = familyMemberArray[indexPath.row - 1].familyMemberNRIC {
                cell.nricFinLabel.text = NricFinMask.maskUserId(nricString)
            }

            if let imageString = familyMemberArray[indexPath.row - 1].familyMemberImage {
                let image = UIImage(named: imageString)
                cell.familyMemberImageView.image = image

                if cell.selectFamilyMemberButton.isSelected {
                    cell.familyMemberImageView.alpha = 1.0
                } else {
                    cell.familyMemberImageView.alpha = 0.50
                }
            }

            if selectedRowsIndexPathArray.contains(indexPath) {
                cell.selectFamilyMemberButton.isSelected = true
                cell.familyMemberImageView.alpha = 1.0
                cell.selectFamilyMemberButton.accessibilityLabel = NSLocalizedString("CheckedFamilyMember", comment: "Checked, Family member selected")
            } else {
                cell.selectFamilyMemberButton.isSelected = false
                cell.familyMemberImageView.alpha = 0.50
                cell.selectFamilyMemberButton.accessibilityLabel = NSLocalizedString("UncheckedFamilyMember", comment: "Unchecked, Family member not selected")
            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        self.viewWillLayoutSubviews()
    }

}

extension FamilyMemberGroupCheckInViewController: NoFamilyMemberDelegate {
    func addFamilyMemberButtonTapped() {
        let vc = UIStoryboard(name: "SettingsView", bundle: Bundle.main).instantiateViewController(withIdentifier: "AddFamilyMemberViewController") as? AddFamilyMemberViewController
        self.navigationController?.pushViewController(vc!, animated: true)
    }
}
