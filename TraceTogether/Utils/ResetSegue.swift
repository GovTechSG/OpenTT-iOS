//
//  ResetSegue.swift
//  OpenTraceTogether

import UIKit

class ResetSegue: UIStoryboardSegue {
    override func perform() {
        source.navigationController?.setViewControllers([destination], animated: true)
    }
}
