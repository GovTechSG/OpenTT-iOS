//
//  SettingsViewController.swift
//  OpenTraceTogether

import UIKit
import SafariServices

class SettingsViewController: UIViewController {

    @IBOutlet var settingsTableView: UITableView!
    @IBOutlet var versionLabel: UILabel!
    @IBOutlet weak var safeEntryBtn: UIBarButtonItem!

    private var viewModel: SettingsViewModel!

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        viewModel = SettingsViewModel(delegate: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        settingsTableView.register(UINib(nibName: "SettingsCustomTableViewCell", bundle: nil), forCellReuseIdentifier: "settingsCell")
        settingsTableView.tableFooterView = UIView(frame: .zero)
        viewModel.viewDidLoad()
        safeEntryBtn.accessibilityLabel = NSLocalizedString("ScanQRCode", comment: "Scan the SafeEntry QR code")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.viewDidAppear()
    }

    @IBAction func safeEntryButtonClicked(_ sender: Any) {
        let storyboard = UIStoryboard(name: "SafeEntry", bundle: nil)
        let tabbarVC = storyboard.instantiateViewController(withIdentifier: "SafeEntryFlow") as! SafeEntryTabBarController
        present(tabbarVC, animated: false, completion: nil)
    }
}

extension SettingsViewController: SettingsViewModelDelegate {
    func setVersionText(text: String) {
        versionLabel.text = text
    }

    func removeSafeEntryBarItem() {
        navigationItem.rightBarButtonItems?.removeAll(where: { $0 == self.safeEntryBtn })
    }

    func setBadge(isNew: Bool) {
        tabBarItem.isNew = isNew
    }

    func reloadRow(at indexPath: IndexPath) {
        settingsTableView.reloadRows(at: [indexPath], with: .none)
    }

    func gotoProfile() {
        performSegue(withIdentifier: "showYourProfileSegue", sender: self)
    }

    func gotoManageFamilyMembers() {
        performSegue(withIdentifier: "showManageFamilyMembers", sender: self)
    }

    func gotoManageAlerts() {
        performSegue(withIdentifier: "showManageAlerts", sender: self)
    }

    func gotoChangeLanguage() {
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
    }

    func gotoHelp() {
        performSegue(withIdentifier: "showHelp", sender: nil)
    }

    func gotoReportVulnerability() {
        let vc = SFSafariViewController(url: URL(string: "https://www.tech.gov.sg/report_vulnerability")!)
        present(vc, animated: true)
    }

    func gotoSubmitErrorLogs() {
        let vc = self.storyboard!.instantiateViewController(withIdentifier: "SubmitErrorLogsViewController")
        navigationController?.pushViewController(vc, animated: true)
    }

    func gotoTipsAndShortcuts() {
        let vc = UIStoryboard(name: "SettingsShortcut", bundle: nil).instantiateInitialViewController()!
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension SettingsViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows(in: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = viewModel.row(at: indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingsCell", for: indexPath) as! SettingsCustomTableViewCell
        cell.selectionStyle = .none
        cell.settingCellTitleLabel.text = row.title
        cell.settingNewLabel.isHidden = !row.isNew
        cell.settingCellTitleLabel.accessibilityLabel = row.title + "." + NSLocalizedString("TapToSeeDetails", comment: "Tap To See Details")
        cell.settingNewLabel.accessibilityLabel = NSLocalizedString("New", comment: "NEW")
        cell.settingNewLabel.text = NSLocalizedString("New", comment: "NEW")
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.selectRow(at: indexPath)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 48.0))
        sectionView.backgroundColor = .white

        let sectionlabel = UILabel(frame: CGRect(x: 24, y: 12, width: view.frame.size.width, height: 24))
        sectionlabel.font = UIFont.systemFont(ofSize: 18.0, weight: .semibold)
        sectionlabel.textColor = UIColor(red: 79.0/255.0, green: 79.0/255.0, blue: 79.0/255.0, alpha: 1.0)
        sectionlabel.text = viewModel.section(at: section).title
        sectionlabel.accessibilityLabel = viewModel.section(at: section).title + NSLocalizedString("Section", comment: "Section")

        sectionView.addSubview(sectionlabel)
        return sectionView
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 32.0))
        footerView.alpha = 0
        return footerView
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 48.0
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 48.0
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 32.0
    }
}
