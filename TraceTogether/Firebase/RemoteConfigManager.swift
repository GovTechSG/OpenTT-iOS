//
//  RemoteConfigManager.swift
//  OpenTraceTogether

import UIKit
import Firebase

/**
 This class automatically fetching remote config from server everytime app move to foreground
 and call observers to update their UI
 */
class RemoteConfigManager {

    static var shared = RemoteConfigManager()

    var togglePossibleExposure: Bool {
        return true
    }

    //TODO: Add other RemoteConfigKeys
    private struct Observer {
        weak var observer: AnyObject?
        var selector: Selector!
    }

    private var observers: [Observer] = []

    init() {
        let defaultRecommendedMinimumVersionIOS = "0"
        let defaultMandatoryMinimumVersionIOS = "0"
        let defaultLatestUpdateVideoURL = ""
        let defaultToggleBoost = ""
        let defaultTogglePossibleExposure = "true"

        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 3600

        let remoteConfig = RemoteConfig.remoteConfig()
        remoteConfig.configSettings = settings
        remoteConfig.setDefaults([
            RemoteConfigKeys.recommendedMinimumVersionIOS: defaultRecommendedMinimumVersionIOS as NSObject,
            RemoteConfigKeys.mandatoryMinimumVersionIOS: defaultMandatoryMinimumVersionIOS as NSObject,
            RemoteConfigKeys.latestUpdateVideoURL: defaultLatestUpdateVideoURL as NSObject,
            RemoteConfigKeys.toggleBoost: defaultToggleBoost as NSObject,
            RemoteConfigKeys.togglePossibleExposure: defaultTogglePossibleExposure as NSObject,
        ])

        fetch()
        NotificationCenter.default.addObserver(self, selector: #selector(fetch), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    @objc private func fetch() {
        RemoteConfig.remoteConfig().fetchAndActivate { (status, _) in
            guard status == .successFetchedFromRemote else {
                return
            }
            self.observers.removeAll(where: { $0.observer == nil })
            self.observers.forEach { $0.observer!.performSelector(onMainThread: $0.selector, with: nil, waitUntilDone: false) }
        }
    }

    ///Add an observer. No need to remove as it is a weak reference
    func addObserver(_ observer: AnyObject, selector: Selector) {
        observers.append(Observer(observer: observer, selector: selector))
    }
}
