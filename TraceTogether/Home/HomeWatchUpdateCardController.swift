//
//  HomeWatchUpdateCardController.swift
//  OpenTraceTogether

import UIKit
import AVKit
import FirebaseRemoteConfig

class HomeWatchUpdateCardController: UIViewController {
    var observers = [NSObjectProtocol]()

    var latestUpdateVideoURLString: String? {
        return RemoteConfig.remoteConfig()[RemoteConfigKeys.latestUpdateVideoURL].stringValue
    }
    var playerViewController: AVPlayerViewController?
    var player: AVPlayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        observers.append(NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: OperationQueue.main) {
            [unowned self] _ in
            guard self.playerViewController?.player != nil else {
                return
            }
            self.playerViewController!.player = nil
        })
        observers.append(NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: OperationQueue.main) {
            [unowned self] _ in
            guard self.player != nil && self.playerViewController != nil else {
                return
            }
            self.playerViewController!.player = self.player
        })
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadView()
    }

    @IBAction func watchUpdates() {
        player = AVPlayer(url: URL(string: latestUpdateVideoURLString!)!)
        if (playerViewController == nil) {
            playerViewController = AVPlayerViewController()
        }
        playerViewController!.player = player
        present(playerViewController!, animated: true) {
            self.player!.play()
        }
    }

    func reloadView() {
        view.isHidden = (latestUpdateVideoURLString ?? "").isEmpty
    }

    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
