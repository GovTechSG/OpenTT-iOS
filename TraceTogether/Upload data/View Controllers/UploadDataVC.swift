//
//  UploadDataVC.swift
//  OpenTraceTogether

import UIKit
import CoreData
import Firebase
import FirebaseFunctions

class UploadDataViewController: UIViewController {

    // MARK: - Local
    private var uploadStepsNavigationVC: UINavigationController?
    var _preferredScreenEdgesDeferringSystemGestures: UIRectEdge = []

    // MARK: - Delegates

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Reset the Steps navigation vc whenever user re-enter this tab
        uploadStepsNavigationVC?.popToRootViewController(animated: false)

    }

    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        return _preferredScreenEdgesDeferringSystemGestures
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? UINavigationController {
            uploadStepsNavigationVC = vc
        }
    }

}
