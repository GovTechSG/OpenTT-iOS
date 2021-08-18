//
//  HistoryMasterViewController.swift
//  OpenTraceTogether

import UIKit

class HistoryMasterViewController: UIViewController {

    @IBOutlet weak var masterParentView: UIView!
    @IBOutlet weak var possibleExposureButton: UIButton!
    @IBOutlet weak var allRecordsButton: UIButton!

    var childTabBarController: UITabBarController!

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        makeThisPageNewForDebugPurpose()
        tabBarItem.isNew = !UserDefaults.standard.bool(forKey: "HistoryTabVisited")
    }

    private func makeThisPageNewForDebugPurpose() {
        #if DEBUG
        UserDefaults.standard.set(false, forKey: "HistoryTabVisited")
        #endif
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let childTBC = segue.destination as? UITabBarController {
            childTabBarController = childTBC
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        RemoteConfigManager.shared.addObserver(self, selector: #selector(reloadView))
        UserDefaults.standard.set(true, forKey: "HistoryTabVisited")
        tabBarItem.isNew = false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        reloadView()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        childTabBarController.selectedIndex = 0
        reloadView()
    }

    @IBAction func actionButtonPressed(_ sender: UIButton) {
        childTabBarController.selectedIndex = sender.tag
        reloadView()
    }

    @objc func reloadView() {
        let showTab = SafeEntryUtils.isUserAllowedToSafeEntry()
        possibleExposureButton.isHidden = !showTab

        let tag = childTabBarController.selectedIndex
        switch tag {
        case 0:
            possibleExposureButton.backgroundColor = UIColor.clear
            possibleExposureButton.setTitleColor(UIColor(red: 189.0/255.0, green: 189.0/255.0, blue: 189.0/255.0, alpha: 1.0), for: .normal)
            allRecordsButton.backgroundColor = UIColor(red: 242.0/255.0, green: 242.0/255.0, blue: 242.0/255.0, alpha: 1.0)
            allRecordsButton.setTitleColor(UIColor(red: 79.0/255.0, green: 79.0/255.0, blue: 79.0/255.0, alpha: 1.0), for: .normal)
            allRecordsButton.titleLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: .bold)
            break
        default:
            allRecordsButton.backgroundColor = UIColor.clear
            allRecordsButton.setTitleColor(UIColor(red: 189.0/255.0, green: 189.0/255.0, blue: 189.0/255.0, alpha: 1.0), for: .normal)
            possibleExposureButton.backgroundColor = UIColor(red: 242.0/255.0, green: 242.0/255.0, blue: 242.0/255.0, alpha: 1.0)
            possibleExposureButton.setTitleColor(UIColor(red: 79.0/255.0, green: 79.0/255.0, blue: 79.0/255.0, alpha: 1.0), for: .normal)
            possibleExposureButton.titleLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: .bold)
            break
        }
    }
}
