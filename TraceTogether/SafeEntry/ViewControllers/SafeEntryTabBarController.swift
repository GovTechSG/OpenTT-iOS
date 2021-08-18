//
//  SafeEntryTabBarController.swift
//  OpenTraceTogether

import UIKit

class SafeEntryTabBarController: UITabBarController {
    weak var userDelegate: UINavigationController?
    var isGroupCheckInFlow = false
    var selectedGroupIDs: [String] = [] {
        didSet {
            isGroupCheckInFlow = true
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
    }

}
