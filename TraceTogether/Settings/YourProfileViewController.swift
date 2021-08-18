//
//  YourProfileViewController.swift
//  OpenTraceTogether

import Foundation
import UIKit

class YourProfileViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var formTable: UITableView!

    var cells = [UITableViewCell]()

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let idType = UserDefaults.standard.string(forKey: "idType") else {
            LogMessage.create(type: .Error, title: "\(#function) ID type is missing", details: [:], collectable: true)
            return
        }

        let profileType = NricFinChecker.checkIdType(idType: idType)
        let profileController = FormRegisterProfileController.from(profileType)
        profileController.tableView = formTable
        profileController.setupViewForStaticProfile()

        cells = profileController.cells[0].filter { !(($0 as? FormLabelCell)?.valueLabel.text?.isEmpty ?? true) }

        LogMessage.create(type: .Info, title: "\(#function)", details: ["profileType": profileType.rawValue], collectable: true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AnalyticManager.setScreenName(screenName: "ProfilePage", screenClass: "YourProfileViewController")
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = cells[indexPath.row] as? FormLabelCell
        cell?.titleLabel.accessibilityLabel = cell?.titleLabel.text
        cell?.valueLabel.accessibilityLabel = cell?.valueLabel.text
        return cells[indexPath.row]
    }
}
