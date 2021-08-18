//
//  PassportReOnboardingViewController.swift
//  OpenTraceTogether

import UIKit

class PassportReOnboardingViewController: UIViewController, NetworkIssuesDelegate {
    lazy var passportUserReRegistrationScreen = UIStoryboard(name: "PassportReOnboarding", bundle: nil).instantiateViewController(withIdentifier: "PassportReRegistrationViewController") as! PassportReRegistrationViewController
    lazy var networkIssueScreen = UIStoryboard(name: "PassportReOnboarding", bundle: nil).instantiateViewController(withIdentifier: "InternetUnavailableViewController") as! InternetUnavailableViewController
    lazy var serverDownScreen = UIStoryboard(name: "PassportReOnboarding", bundle: nil).instantiateViewController(withIdentifier: "ServerDownViewController") as! ServerDownViewController
    var reachability: Reachability {
         let appDelegate = UIApplication.shared.delegate as! AppDelegate
         return appDelegate.reachability!
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        networkIssueScreen.userDelegate = self
        serverDownScreen.userDelegate = self
        checkIfPassportUserRequiresReregistration()
    }

    func retryAction() {
        checkIfPassportUserRequiresReregistration()
    }

    func checkIfPassportUserRequiresReregistration() {
        let topModal = self.presentedViewController
        topModal?.dismiss(animated: false, completion: nil)

        LoadingViewController.present(in: self) {
            if SafeEntryUtils.isPassportUser() {
                if self.reachability.connection == .unavailable {
                    LoadingViewController.dismiss(in: self) {[weak self] in
                        self?.showNetworkIssueView()
                    }
                } else {
                    FirebaseAPIs.getPassportStatus {[weak self] (status, error) in
                        guard let self = self else {
                            return
                        }
                        LoadingViewController.dismiss(in: self) {
                            if error != nil {
                                self.showServerDownView()
                                return
                            }
                            if status == false {
                                self.showPassportReregistrationView()
                                return
                            }
                            UserDefaults.standard.setValue(true, forKey: "PassportVerificationStatus")
                            let appDelegate = UIApplication.shared.delegate as! AppDelegate
                            appDelegate.navigateToCorrectPage()
                        }
                    }
                }
            }
        }
    }

    func showPassportReregistrationView() {
        passportUserReRegistrationScreen.modalPresentationStyle = .overFullScreen
        passportUserReRegistrationScreen.modalTransitionStyle = .crossDissolve
        let topModal = self.presentedViewController
        topModal?.dismiss(animated: false, completion: nil)
        present(passportUserReRegistrationScreen, animated: false)
    }

    func showNetworkIssueView() {
        networkIssueScreen.modalPresentationStyle = .overFullScreen
        networkIssueScreen.modalTransitionStyle = .crossDissolve
        let topModal = self.presentedViewController
        topModal?.dismiss(animated: false, completion: nil)
        present(networkIssueScreen, animated: false)
    }

    func showServerDownView() {
        serverDownScreen.modalPresentationStyle = .overFullScreen
        serverDownScreen.modalTransitionStyle = .crossDissolve
        let topModal = self.presentedViewController
        topModal?.dismiss(animated: false, completion: nil)
        present(serverDownScreen, animated: false)
    }
}
