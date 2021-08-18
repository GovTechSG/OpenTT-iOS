//
//  SettingsSiriShortcutViewController.swift
//  OpenTraceTogether

import UIKit
import SafariServices

class SettingsShortcutViewController: UITableViewController, SettingsShortcutDelegate {

    private let viewModel = SettingsShortcutViewModel()

    private var cells = [UITableViewCell]()

    override func viewDidLoad() {
        viewModel.delegate = self
        viewModel.viewDidLoad()
    }

    func addHeader() {
        cells.append(tableView.dequeueReusableCell(withIdentifier: "HeaderCell")!)
    }

    func addSiriSection() {
        cells.append(tableView.dequeueReusableCell(withIdentifier: "SiriSectionCell")!)
    }

    func addSiriRow(withTitle title: String, siriButton: AnyObject) {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SiriRowCell") as! SettingsShortcutSiriCell
        cell.titleLabel.text = title

        let button = siriButton as! UIButton
        cell.buttonContainer.addSubview(button)
        cell.buttonContainer.trailingAnchor.constraint(equalTo: button.trailingAnchor).isActive = true
        cell.buttonContainer.topAnchor.constraint(equalTo: button.topAnchor).isActive = true
        cell.buttonContainer.bottomAnchor.constraint(equalTo: button.bottomAnchor).isActive = true
        cell.buttonContainer.leadingAnchor.constraint(equalTo: button.leadingAnchor).isActive = true

        cells.append(cell)
    }

    func addWidgetSection() {
        cells.append(tableView.dequeueReusableCell(withIdentifier: "WidgetSectionCell")!)
    }

    func presentSiriModal(modal: AnyObject) {
        present(modal as! UIViewController, animated: true, completion: nil)
    }

    func dismissSiriModal() {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func siriHowThisWorksTapped(_ sender: Any) {
        let vc = SFSafariViewController(url: URL(string: "https://support.tracetogether.gov.sg/hc/en-sg/articles/360057640553-iOS-shortcut-Using-Hey-Siri-or-Back-Tap-for-SafeEntry")!)
        present(vc, animated: true)
    }

    @IBAction func widgetHowThisWorksTapped(_ sender: Any) {
        let vc = SFSafariViewController(url: URL(string: "https://support.tracetogether.gov.sg/hc/en-sg/articles/360055793414-iOS-shortcut-Using-widgets-for-SafeEntry")!)
        present(vc, animated: true)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return cells[indexPath.row]
    }
}
