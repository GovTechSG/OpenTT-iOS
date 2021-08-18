//
//  PassportHoldingViewController.swift
//  OpenTraceTogether

import UIKit

class PassportHoldingViewController: UIViewController {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var birthTitleLabel: UILabel!
    @IBOutlet weak var birthLabel: UILabel!
    @IBOutlet weak var nationalityTitleLabel: UILabel!
    @IBOutlet weak var nationalityLabel: UILabel!
    @IBOutlet weak var passportTitleLabel: UILabel!
    @IBOutlet weak var passportNumLabel: UILabel!
    @IBOutlet weak var savedLabel: UILabel!
    @IBOutlet weak var nextStepLabel: UILabel!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var activateAppButton: UIButton!
    @IBOutlet weak var safeTravelLinkTextView: UITextView!

    var passportController = FormRegisterPassportProfileController()

    override func viewDidLoad() {

        self.view.accessibilityElements = [nameLabel!, savedLabel!, birthTitleLabel!, birthLabel!, nationalityTitleLabel!, nationalityLabel!, passportTitleLabel!, passportNumLabel!, editButton!, nextStepLabel!, activateAppButton!, safeTravelLinkTextView!]

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        passportController.setupViewForPassportHoldingVC(self)
    }

    @IBAction func editBtnPressed(_ sender: UIButton) {
        let vc = UIStoryboard(name: "FormRegister", bundle: nil).instantiateInitialViewController() as! FormRegisterViewController
        vc.profileType = .Visitor
        navigationController?.pushViewController(vc, animated: true)
    }

    @IBAction func activateBtnPressed(_ sender: UIButton) {
        passportController.activateApp(in: self)
    }
}
