//
//  SENoFavourites.swift
//  OpenTraceTogether

import UIKit

class SENoFavouritesViewController: UIViewController {

    @IBAction func seeMyHistoryButtonPressed(_ sender: UIButton) {
        let rootTabBarController = view.window!.rootViewController?.children.first(where: { $0 is UITabBarController }) as! UITabBarController
        dismiss(animated: true) {
            rootTabBarController.selectedIndex = 1
        }
    }

}
