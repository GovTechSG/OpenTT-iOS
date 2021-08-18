//
//  SettingsShortcutViewModel.swift
//  OpenTraceTogether

import Foundation
import Intents
import IntentsUI

protocol SettingsShortcutDelegate: AnyObject {
    func addHeader()
    func addSiriSection()
    func addSiriRow(withTitle title: String, siriButton: AnyObject)
    func addWidgetSection()
    func presentSiriModal(modal: AnyObject)
    func dismissSiriModal()
}

class SettingsShortcutViewModel {

    weak var delegate: SettingsShortcutDelegate?

    private var viewModel_iOS12: AnyObject?

    func viewDidLoad() {
        delegate?.addHeader()

        if #available(iOS 12.0, *) {
            delegate?.addSiriSection()

            let viewModel_iOS12 = SettingsShortcutViewModel_iOS12()
            viewModel_iOS12.delegate = delegate

            let shortcuts = SiriShortcutModel.allEntities
            for s in shortcuts {
                let button = viewModel_iOS12.createSiriButton(id: s.id, title: "TT " + s.title, delegate: delegate)
                delegate?.addSiriRow(withTitle: s.title, siriButton: button)
            }
            self.viewModel_iOS12 = viewModel_iOS12
        }

        if #available(iOS 14.0, *) {
            delegate?.addWidgetSection()
        }
    }
}

@available(iOS 12.0, *)
private class SettingsShortcutViewModel_iOS12: NSObject, INUIAddVoiceShortcutButtonDelegate, INUIAddVoiceShortcutViewControllerDelegate, INUIEditVoiceShortcutViewControllerDelegate {

    weak var delegate: SettingsShortcutDelegate?

    func createSiriButton(id: String, title: String, delegate: SettingsShortcutDelegate?) -> AnyObject {

        let activity = NSUserActivity(activityType: id)
        activity.title = title
        activity.suggestedInvocationPhrase = title
        activity.persistentIdentifier = NSUserActivityPersistentIdentifier(id)
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true

        let button = INUIAddVoiceShortcutButton(style: .whiteOutline)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.shortcut = INShortcut(userActivity: activity)
        button.delegate = self

        return button
    }

    func present(_ addVoiceShortcutViewController: INUIAddVoiceShortcutViewController, for addVoiceShortcutButton: INUIAddVoiceShortcutButton) {
        addVoiceShortcutViewController.delegate = self
        delegate?.presentSiriModal(modal: addVoiceShortcutViewController)
    }

    func present(_ editVoiceShortcutViewController: INUIEditVoiceShortcutViewController, for addVoiceShortcutButton: INUIAddVoiceShortcutButton) {
        editVoiceShortcutViewController.delegate = self
        delegate?.presentSiriModal(modal: editVoiceShortcutViewController)
    }

    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
        if let error = error {
            LogMessage.create(type: .Error, title: #function, details: "\(error.localizedDescription)")
        }
        delegate?.dismissSiriModal()
    }

    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        delegate?.dismissSiriModal()
    }

    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didUpdate voiceShortcut: INVoiceShortcut?, error: Error?) {
        if let error = error {
            LogMessage.create(type: .Error, title: #function, details: "\(error.localizedDescription)")
        }
        delegate?.dismissSiriModal()
    }

    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID) {
        delegate?.dismissSiriModal()
    }

    func editVoiceShortcutViewControllerDidCancel(_ controller: INUIEditVoiceShortcutViewController) {
        delegate?.dismissSiriModal()
    }
}
