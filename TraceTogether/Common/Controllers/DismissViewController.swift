//
//  DismissViewController.swift
//  OpenTraceTogether

import UIKit

class DismissViewController: UIStoryboardSegue {
   override func perform() {
       self.source.presentingViewController?.dismiss(animated: true, completion: nil)
  }
}

protocol Nondismissable: UIViewController {

}
