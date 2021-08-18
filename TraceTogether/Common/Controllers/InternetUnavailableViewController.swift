//
//  InternetUnavailableViewController.swift
//  OpenTraceTogether

import UIKit

protocol NetworkIssuesDelegate: UIViewController {
    func retryAction()
}
class InternetUnavailableViewController: UIViewController {
    weak var userDelegate: NetworkIssuesDelegate?
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    @IBAction func retryAction(_ sender: Any?) {
        userDelegate?.retryAction()
    }
}

class ServerDownViewController: UIViewController {
    weak var userDelegate: NetworkIssuesDelegate?
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func retryAction(_ sender: Any?) {
        userDelegate?.retryAction()
    }
}
