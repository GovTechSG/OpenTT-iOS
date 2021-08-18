//
//  LoadingViewController.swift
//  OpenTraceTogether

import UIKit

class LoadingViewController: UIViewController {

    static func present(in vc: UIViewController, completion: (() -> Void)? = nil) {
        let loadingVC = LoadingViewController()
        loadingVC.modalTransitionStyle = .crossDissolve
        loadingVC.modalPresentationStyle = .overFullScreen
        vc.present(loadingVC, animated: true, completion: completion)
    }

    static func dismiss(in vc: UIViewController, completion: (() -> Void)? = nil) {
        if vc.presentedViewController is LoadingViewController {
            vc.dismiss(animated: false, completion: completion)
        } else {
            completion?()
        }
    }
}
