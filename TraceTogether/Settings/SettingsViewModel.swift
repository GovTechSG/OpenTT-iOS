//
//  SettingsViewModel.swift
//  OpenTraceTogether

import Foundation

@objc protocol SettingsViewModelDelegate: NSObjectProtocol {
    func reloadRow(at indexPath: IndexPath)
    func removeSafeEntryBarItem()
    func setBadge(isNew: Bool)
    func setVersionText(text: String)
    func gotoProfile()
    func gotoManageFamilyMembers()
    func gotoManageAlerts()
    func gotoChangeLanguage()
    func gotoHelp()
    func gotoReportVulnerability()
    func gotoSubmitErrorLogs()
    func gotoTipsAndShortcuts()
}

class SettingsViewModel {

    class Row {
        let title: String
        var isNew: Bool {
            get {
                return newId != nil && !UserDefaults.standard.bool(forKey: newId!)
            } set {
                if let newId = newId {
                    UserDefaults.standard.set(!newValue, forKey: newId)
                }
            }
        }
        fileprivate let selector: Selector?
        fileprivate let newId: String?

        /** - Parameter newId: To indicate whether the user already seen this feature or not. */
        init(title: String, selector: Selector?, newId: String? = nil) {
            self.title = NSLocalizedString(title, comment: "")
            self.selector = selector
            self.newId = newId
        }
    }

    class Section {
        let title: String
        fileprivate var rows = [Row]()

        init(title: String) {
            self.title = NSLocalizedString(title, comment: "")
        }
    }

    private weak var delegate: SettingsViewModelDelegate?
    private var sections = [Section]()

    init(delegate: SettingsViewModelDelegate?) {
        self.delegate = delegate

        //Account section
        let accountSection = Section(title: "Account")
        sections.append(accountSection)

        let profileRow = Row(title: "YourProfile", selector: #selector(delegate?.gotoProfile))
        accountSection.rows.append(profileRow)

        if FeatureFlags.settingsManageFamilyMembersEnabled, SafeEntryUtils.isUserAllowedToSafeEntry() {
            let manageFMRow = Row(title: "ManageFamilyMembers", selector: #selector(delegate?.gotoManageFamilyMembers), newId: "ManageFamilyMemberNewButton")
            accountSection.rows.append(manageFMRow)
        }

        if FeatureFlags.settingsManageAlertsEnabled {
            let manageAlertsRow = Row(title: "ManageAlerts", selector: #selector(delegate?.gotoManageAlerts), newId: "ManageAlertsNewButton")
            accountSection.rows.append(manageAlertsRow)
        }

        if #available(iOS 13.0, *) {
            let changeLanguageRow = Row(title: "ChangeLanguage", selector: #selector(delegate?.gotoChangeLanguage))
            accountSection.rows.append(changeLanguageRow)
        }

        //Help section
        let helpSection = Section(title: "HelpFeedback")
        sections.append(helpSection)

        let helpRow = Row(title: "Help", selector: #selector(delegate?.gotoHelp))
        helpSection.rows.append(helpRow)

        let reportVulnRow = Row(title: "ReportVuln", selector: #selector(delegate?.gotoReportVulnerability))
        helpSection.rows.append(reportVulnRow)

        if FeatureFlags.settingsSubmitLogsEnabled {
            let submitLogsRow = Row(title: "SubmitErrorLogs", selector: #selector(delegate?.gotoSubmitErrorLogs), newId: "SubmitErrorLogsVisited")
            helpSection.rows.append(submitLogsRow)
        }

        //Others section
        let othersSection = Section(title: "Others")
        sections.append(othersSection)

        if #available(iOS 12.0, *), SafeEntryUtils.isUserAllowedToSafeEntry() {
            let tipsRow = Row(title: "TipsAndShortcuts", selector: #selector(delegate?.gotoTipsAndShortcuts), newId: "TipsAndShortcutsVisited")
            othersSection.rows.append(tipsRow)
        }

        //Filter empty section
        sections = sections.filter { $0.rows.count > 0 }

        makeThisPageNewForDebugPurpose()
        reloadBadge()
    }

    private func makeThisPageNewForDebugPurpose() {
        #if DEBUG
        sections.forEach { $0.rows.forEach { $0.isNew = true }}
        #endif
    }

    /// Reload the "NEW" indicator.
    private func reloadBadge() {
        let hasNewFeature = sections.contains { $0.rows.contains { $0.isNew } }
        delegate?.setBadge(isNew: hasNewFeature)
    }

    func viewDidLoad() {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            delegate?.setVersionText(text: String(format: NSLocalizedString("AppVersion", comment: "App Version"), version))
        }
        if !SafeEntryUtils.isUserAllowedToSafeEntry() {
            delegate?.removeSafeEntryBarItem()
        }
    }

    func viewDidAppear() {
        AnalyticManager.setScreenName(screenName: "SettingsPage", screenClass: "SettingsViewController")
    }

    func numberOfSections() -> Int {
        return sections.count
    }

    func numberOfRows(in section: Int) -> Int {
        return sections[section].rows.count
    }

    func section(at index: Int) -> Section {
        return sections[index]
    }

    func row(at indexPath: IndexPath) -> Row {
        return sections[indexPath.section].rows[indexPath.row]
    }

    func selectRow(at indexPath: IndexPath) {
        let row = sections[indexPath.section].rows[indexPath.row]
        delegate?.perform(row.selector)

        if row.isNew {
            row.isNew = false
            delegate?.reloadRow(at: indexPath)
            reloadBadge()
        }
    }
}
