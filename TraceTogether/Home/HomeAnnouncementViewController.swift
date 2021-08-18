//
//  HomeAnnouncementViewController.swift
//  OpenTraceTogether

import UIKit
import FirebaseRemoteConfig
import SafariServices

class AnnouncementModel {
    var id: Int = 0
    var text: String = ""
    var url: URL?
    var minAppVersion: String?
    var maxAppVersion: String?

    func reload() {

        var announcement: [String: Any?]? = [:]
        announcement = RemoteConfig.remoteConfig()[RemoteConfigKeys.announcementIOS].jsonValue as? [String: Any?]

        let lang = String(NSLocale.preferredLanguages.first!.split(separator: "-").first!)
        let texts = announcement?["text"] as? [String: String?]
        let urlString = announcement?["url"] as? String

        id = announcement?["id"] as? Int ?? 0
        text = (texts?[lang] as? String) ?? (texts?["en"] as? String) ?? ""
        url = URL(string: urlString ?? "")
        minAppVersion = announcement?["minAppVersion"] as? String
        maxAppVersion = announcement?["maxAppVersion"] as? String
    }

    func shouldShowAnnouncement() -> Bool {
        var prevId = 0
        prevId = UserDefaults.standard.integer(forKey: RemoteConfigKeys.announcementIOS)
        let currentVersion = VersionNumberHelper.getCurrentVersion()
        if self.minAppVersion?.isVersionLowerThanOrEqualTo(currentVersion) ?? true &&
            self.maxAppVersion?.isVersionGreaterThanOrEqualTo(currentVersion) ?? true &&
            !self.text.isEmpty && self.id > prevId {
            return true
        }
        return false
    }
}

class HomeAnnouncementViewController: UIViewController {

    @IBOutlet var announcementText: UILabel!
    @IBOutlet var closeButton: UIButton!
    @IBOutlet var zeroHeightConstraint: NSLayoutConstraint!

    var announcement = AnnouncementModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.isAccessibilityElement = false
        self.announcementText.isAccessibilityElement = true
        closeButton.accessibilityLabel = NSLocalizedString("Close", comment: "close")
        
        // Reset on load so it can be tested again
        #if DEBUG
        UserDefaults.standard.removeObject(forKey: RemoteConfigKeys.announcementIOS)
        #endif

        reloadView()
        fetchData()
        NotificationCenter.default.addObserver(self, selector: #selector(fetchData), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    @objc func fetchData() {
        RemoteConfig.remoteConfig().fetchAndActivate { (_, _) in self.reloadView() }
    }

    func reloadView() {
        announcement.reload()

        let hide = !announcement.shouldShowAnnouncement()
        DispatchQueue.main.async { [weak self] in
            if let self = self {
                self.announcementText.setAttributedText(markupString: self.announcement.text)
                self.announcementText.accessibilityLabel = self.announcement.text
                self.zeroHeightConstraint.priority = UILayoutPriority(rawValue: UILayoutPriority.RawValue(hide ? 999 : 500))
                self.view.superview!.layoutIfNeeded()
            }
        }
    }

    @IBAction func announcementPressed() {
        if let url = announcement.url {
            present(SFSafariViewController(url: url), animated: true, completion: nil)
        }
    }

    @IBAction func dismiss() {
        UserDefaults.standard.set(announcement.id, forKey: RemoteConfigKeys.announcementIOS)
        UIView.animate(withDuration: 0.3) { self.reloadView() }
    }
}
