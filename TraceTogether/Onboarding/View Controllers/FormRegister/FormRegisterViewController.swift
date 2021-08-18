//
//  FormRegisterViewController.swift
//  OpenTraceTogether

import UIKit

/// A container to display tableView and top progress bar
class FormRegisterViewController: UIViewController {
    var profileType: ProfileType = .NRIC
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        LogMessage.create(type: .Info, title: #function, details: ["profileType": profileType.rawValue], collectable: true)
        (segue.destination as! FormRegisterTableViewController).profileType = profileType
    }
}

/// Another container to display tableView. The real implementations are inside each profile.
/// Do not put any specific profile logic here. Put those in each profile and call this VC using FormRegisterProfileControllerDelegate.
class FormRegisterTableViewController: UITableViewController, FormRegisterProfileControllerDelegate {

    @IBOutlet var formAccessoryView: FormAccessoryView!

    var headerCell: UITableViewCell! { get { profileController.headerCell }}
    var footerCell: FormFooterCell! { get { profileController.footerCell }}
    var cells: [[UITableViewCell]] = []

    var profileController: FormRegisterProfileController!
    var profileType: ProfileType = .NRIC

    override func viewDidLoad() {
        super.viewDidLoad()
        profileController = FormRegisterProfileController.from(profileType)
        profileController.tableView = tableView
        profileController.delegate = self
        profileController.setupView()
        reloadView()
        LogMessage.create(type: .Info, title: #function, details: ["profileType": profileType.rawValue], collectable: true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AnalyticManager.setScreenName(screenName: profileController.screenName, screenClass: "RegisterFormViewController")
        if let textFieldCell = profileController.cells[0][0] as? FormTextFieldCell {
            textFieldCell.textField.becomeFirstResponder()
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        formAccessoryView.fields = getFormFields().map { $0.textField! }
        cells = [[headerCell]] + profileController.cells + [[footerCell]]
        return cells.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return cells[indexPath.section][indexPath.row]
    }

    func getFormFields() -> [FormTextFieldCell] {
        return cells.reduce([], { $0 + $1 }).filter { $0 is FormTextFieldCell } as! [FormTextFieldCell]
    }

    func reloadView() {
        footerCell.checkBoxButton.accessibilityTraits = .staticText
        if footerCell.checkBoxButton.isSelected {
            footerCell.checkBoxButton.accessibilityLabel = NSLocalizedString("CheckboxSelected", comment: "Agree to Terms and Conditions Checkbox checked")
        } else {
            footerCell.checkBoxButton.accessibilityLabel = NSLocalizedString("CheckboxNotSelected", comment: "Agree to Terms and Conditions Checkbox unchecked")
        }

        let ready = profileController.ready && footerCell.checkBoxButton.isSelected
        footerCell.submitButton.isEnabled = ready
        footerCell.submitButton.backgroundColor = UIColor(hexString: ready ? "#FF6666" : "#F2F2F2")
        getFormFields().forEach { $0.serverError = nil }
    }

    @IBAction func agreeTNCButtonPressed(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        reloadView()
    }

    @IBAction func dismiss() {
        navigationController?.popViewController(animated: true)
    }

    func formRegisterProfileControllerWantsToPerformSegue(controller: FormRegisterProfileController, segueId: String) {
        performSegue(withIdentifier: segueId, sender: nil)
    }

    func formRegisterProfileControllerOnReady(controller: FormRegisterProfileController) {
        reloadView()
    }

    @IBAction func submitButtonPressed() {
        profileController.submit(in: self)
    }
}
