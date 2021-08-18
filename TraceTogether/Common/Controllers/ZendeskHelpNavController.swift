//
//  ZendeskHelpViewController.swift
//  OpenTraceTogether


import ZendeskCoreSDK
import SupportSDK

class ZendeskHelpNavController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        presentHelpCenter()
        self.setNavigationBarHidden(false, animated: false)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AnalyticManager.setScreenName(screenName: "HelpSupport", screenClass: "UINavigationController")
    }

    func presentHelpCenter() {
        let helpCenterUiConfig = HelpCenterUiConfiguration()
        helpCenterUiConfig.showContactOptions = false // hide in help center screen

        let articleUiConfig = ArticleUiConfiguration()
        articleUiConfig.showContactOptions = false   // hide in article screen

        let helpCenterViewController = HelpCenterUi.buildHelpCenterOverviewUi(withConfigs: [helpCenterUiConfig, articleUiConfig])
        pushViewController(helpCenterViewController, animated: true)
    }

}
