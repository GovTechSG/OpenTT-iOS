//
//  ManageFamilyMembersViewController.swift
//  OpenTraceTogether

import UIKit
import CoreData

class ManageFamilyMembersViewController: UIViewController {

    @IBOutlet weak var familyMemberTableView: UITableView!
    @IBOutlet weak var noFamilyMemberView: NoFamilyMemberView!
    @IBOutlet weak var addAnotherPersonBtn: UIButton!
    @IBOutlet weak var familyMemberTableViewHeightConstraint: NSLayoutConstraint!

    var familyMemberArray = [FamilyMemberRef]()
    
    var familyMemberTableViewMaxHeight: CGFloat = 66.0 //Height of one tableView cell

    override func viewDidLoad() {
        super.viewDidLoad()

        familyMemberTableView.register(UINib(nibName: "FamilyMemberTableViewCell", bundle: nil), forCellReuseIdentifier: "familyMemberCell")

        noFamilyMemberView.delegate = self

        addAnotherPersonBtn.contentHorizontalAlignment = .left
    }

    override func viewWillAppear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = true
        fetchData()

        // Handle Accessibility
        addAnotherPersonBtn.accessibilityLabel = NSLocalizedString("AddAnotherPersonForAccessibility", comment: "Add another person")
        if !noFamilyMemberView.isHidden {
            for aView in self.view.subviews {
                if aView != noFamilyMemberView {
                    aView.isAccessibilityElement = false
                    aView.accessibilityElementsHidden = true
                }
            }
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

    func createSECheckInBarButton() {
        var image = UIImage(named: "SEcheck")
        image = image?.withRenderingMode(UIImage.RenderingMode.alwaysOriginal)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(qrScanBtnPressed))
        self.navigationItem.rightBarButtonItem?.accessibilityLabel = NSLocalizedString("ScanQRCode", comment: "Scan the SafeEntry QR code")
    }

    @IBAction func backBtnPressed(_ sender: UIBarButtonItem) {
        self.navigationController?.popViewController(animated: true)
    }

    @objc func qrScanBtnPressed() {
        let storyboard = UIStoryboard(name: "SafeEntry", bundle: nil)
        let tabbarVC = storyboard.instantiateViewController(withIdentifier: "SafeEntryFlow") as! SafeEntryTabBarController
        tabbarVC.userDelegate = self.navigationController
        self.present(tabbarVC, animated: false, completion: nil)
    }

    //Adjust height of tableview based on dynamic content
    override func viewWillLayoutSubviews() {
        DispatchQueue.main.async {
            super.updateViewConstraints()
            self.familyMemberTableViewHeightConstraint?.constant = self.familyMemberTableView.contentSize.height
            self.familyMemberTableViewHeightConstraint?.constant = max(self.familyMemberTableViewMaxHeight, self.familyMemberTableView.contentSize.height)
            self.view.layoutIfNeeded()
        }
    }

    //To accommodate long nav bar title
    func setNavTitle(title: String) {
        let frame = CGRect(x: 0, y: 0, width: 200, height: 40)
        let navTitlelabel = UILabel(frame: frame)
        navTitlelabel.text = title
        navTitlelabel.textColor = UIColor.black
        navTitlelabel.font = UIFont.boldSystemFont(ofSize: 17)
        navTitlelabel.adjustsFontSizeToFitWidth = true
        navTitlelabel.textAlignment = .center
        self.navigationItem.titleView = navTitlelabel
    }

    func fetchData() {
        print("Fetching Data..")

        let fetchRequest: NSFetchRequest<FamilyMember> = FamilyMember.fetchRequest()
        do {
            let familyMembers = try SecureStore.getAllFamilyMembers()
            self.familyMemberArray = familyMembers
            if self.familyMemberArray.count == 0 {
                self.tabBarController?.tabBar.isHidden = true
                self.noFamilyMemberView.isHidden = false
                self.navigationItem.rightBarButtonItem = nil
                setNavTitle(title: "Add Family Members")
            } else {
                self.tabBarController?.tabBar.isHidden = false
                self.noFamilyMemberView.isHidden = true
                createSECheckInBarButton()
                setNavTitle(title: "Manage Family Members")
                self.familyMemberTableView.reloadData()
            }
        } catch {
            print("Fetching data Failed")

        }
    }

    @IBAction func addAnotherPersonBtnPressed(_ sender: UIButton) {
        addFamilyMemberButtonTapped()
    }

    override func viewWillDisappear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = false
    }

}

extension ManageFamilyMembersViewController: UITableViewDelegate, UITableViewDataSource, ManageFamilyMemberDelegate {

    func removeFamilyMember(_ sender: FamilyMemberTableViewCell) {
        guard let indexPath = familyMemberTableView.indexPath(for: sender) else { return }
        showAlert(index: indexPath.row)
    }

    func showAlert(index: Int) {
        guard let nameString = familyMemberArray[index].familyMemberName  else {
            return
        }
        let title = "Remove \(nameString)"
        let message = "To add \(nameString) back, you'll need to add their NRIC/FIN number again"
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        let removeAction = UIAlertAction(title: "Remove", style: .default) { (_: UIAlertAction) in
            print("Remove")
            do {
                try SecureStore.removeFamilyMember(familyMember: self.familyMemberArray[index])
                LogMessage.create(type: .Info, title: "removeFamilyMember", details: "Success", collectable: true)
                self.fetchData()
            } catch {
                LogMessage.create(type: .Error, title: "removeFamilyMember", details: error.localizedDescription, collectable: true)
                print("Deleting failed")
            }
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(removeAction)
        
        self.present(alertController, animated: true, completion: nil)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return familyMemberArray.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "familyMemberCell", for: indexPath) as! FamilyMemberTableViewCell

        cell.delegate = self

        if let nameString = familyMemberArray[indexPath.row].familyMemberName {
            cell.nicknameLabel.text = nameString
        }

        if let nricString = familyMemberArray[indexPath.row].familyMemberNRIC {
            cell.nricFinLabel.text = NricFinMask.maskUserId(nricString)
        }

        if let imageString = familyMemberArray[indexPath.row].familyMemberImage {
            let image = UIImage(named: imageString)
            cell.familyMemberImageView.image = image
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

extension ManageFamilyMembersViewController: NoFamilyMemberDelegate {
    func addFamilyMemberButtonTapped() {
        let vc = UIStoryboard(name: "SettingsView", bundle: Bundle.main).instantiateViewController(withIdentifier: "AddFamilyMemberViewController") as? AddFamilyMemberViewController
        vc?.navigationItem.rightBarButtonItem = nil
        self.navigationController?.pushViewController(vc!, animated: true)
    }
}
