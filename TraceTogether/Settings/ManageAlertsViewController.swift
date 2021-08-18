//
//  ManageAlertsViewController.swift
//  OpenTraceTogether

import UIKit

class ManageAlertsViewController: UIViewController {

    let alertTitles = [NSLocalizedString("ExposureAlerts", comment: "Exposure Alerts"), NSLocalizedString("AppUpdates", comment: "App Updates"), NSLocalizedString("DailyReminder", comment: "Daily Reminder")]
    let alertDescription = [NSLocalizedString("ExposureAlertsDescription", comment: "Exposure Alerts"), NSLocalizedString("AppUpdatesDescription", comment: "App Updates"), NSLocalizedString("DailyReminderDescription", comment: "Daily Reminder")]

    @IBOutlet weak var manageAlertsTableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.manageAlertsTableView.register(UINib(nibName: "ManageAlertCustomTableViewCell", bundle: nil), forCellReuseIdentifier: "alertCell")
        self.manageAlertsTableView.tableFooterView = UIView(frame: .zero)

        //Register to set Defaults value of Switches
        UserDefaults.standard.register(defaults: ["ExposureAlertsSwitch": true])
        UserDefaults.standard.register(defaults: ["AppUpdatesSwitch": true])
        UserDefaults.standard.register(defaults: ["DailyReminderSwitch": false])
    }
}

extension ManageAlertsViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return alertTitles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let alertCell = tableView.dequeueReusableCell(withIdentifier: "alertCell", for: indexPath) as! ManageAlertCustomTableViewCell
        alertCell.alertTitle?.text = alertTitles[indexPath.row]
        alertCell.alertDescription?.text = alertDescription[indexPath.row]
        alertCell.selectionStyle = .none
        alertCell.alertSwitch.tag = indexPath.row
        alertCell.alertSwitch.addTarget(self, action: #selector(alertSwitchStateDidChange(_:)), for: .valueChanged)
        switch indexPath.row {
        case 0:
            if UserDefaults.standard.bool(forKey: "ExposureAlertsSwitch") {
                setAlertSwitchOn(alertCell.alertSwitch, key: "ExposureAlertsSwitch")
            } else {
                setAlertSwitchOff(alertCell.alertSwitch, key: "ExposureAlertsSwitch")
            }
            break
        case 1:
            if UserDefaults.standard.bool(forKey: "AppUpdatesSwitch") {
                setAlertSwitchOn(alertCell.alertSwitch, key: "AppUpdatesSwitch")
            } else {
                setAlertSwitchOff(alertCell.alertSwitch, key: "AppUpdatesSwitch")
            }
            break
        default:
            if UserDefaults.standard.bool(forKey: "DailyReminderSwitch") {
                setAlertSwitchOn(alertCell.alertSwitch, key: "DailyReminderSwitch")
            } else {
                setAlertSwitchOff(alertCell.alertSwitch, key: "DailyReminderSwitch")
            }
        }
        return alertCell
    }

    func setAlertSwitchOn(_ sender: UISwitch, key: String) {
        UserDefaults.standard.set(true, forKey: key)
        sender.setOn(true, animated: true)
        sender.onTintColor = UIColor(red: 0.0/255.0, green: 112.0/255.0, blue: 224.0/255.0, alpha: 0.15)
        sender.thumbTintColor = UIColor(red: 40.0/255.0, green: 89.0/255.0, blue: 157.0/255.0, alpha: 1.0)
        sender.backgroundColor = UIColor.clear
    }

    func setAlertSwitchOff(_ sender: UISwitch, key: String) {
        UserDefaults.standard.set(false, forKey: key)
        sender.setOn(false, animated: true)
        sender.thumbTintColor = UIColor(red: 242.0/255.0, green: 242.0/255.0, blue: 242.0/255.0, alpha: 1.0)
        sender.layer.cornerRadius = (sender.frame.height / 0.75) / 2
        sender.backgroundColor = UIColor(red: 189.0/255.0, green: 189.0/255.0, blue: 189.0/255.0, alpha: 1.0)
    }

    @objc func alertSwitchStateDidChange(_ sender: UISwitch) {
        switch sender.tag {
        case 0:
            if !sender.isOn {
                setAlertSwitchOff(sender, key: "ExposureAlertsSwitch")
            } else {
                setAlertSwitchOn(sender, key: "ExposureAlertsSwitch")
            }
            break
        case 1:
            if !sender.isOn {
                setAlertSwitchOff(sender, key: "AppUpdatesSwitch")
            } else {
                setAlertSwitchOn(sender, key: "AppUpdatesSwitch")
            }
            break
        default:
            if !sender.isOn {
                setAlertSwitchOff(sender, key: "DailyReminderSwitch")
            } else {
                setAlertSwitchOn(sender, key: "DailyReminderSwitch")
            }
        }
    }
}
