//
//  HomeEncounterCardController.swift
//  OpenTraceTogether

import UIKit
import SafariServices

class HomeEncounterCardController: UIViewController {

    @IBOutlet var nearbyLabel: UILabel!
    @IBOutlet var countLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        Services.encounter.observeTodayHighlight(self) { [weak self] in self?.reloadView() }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadView()
    }

    func reloadView() {
        let today = Services.encounter.getTodayHighlight()
        let totalString = String(format: NSLocalizedString("NumOfExchangesToday", comment: ""), NumberFormatter.decimalString(fromNumber: today.total))
        countLabel.text = totalString
        let rangeStr = today.nearbyLowerRange == 0 ? "0" : "\(NumberFormatter.decimalString(fromNumber: today.nearbyLowerRange)) - \(NumberFormatter.decimalString(fromNumber: today.nearbyUpperRange))"
        let nearbyMarkupString = String(format: "<lh:21>\(NSLocalizedString("NumOfDevicesNearby", comment: ""))</lh>", "<fs:18><c:#046CB5>\(rangeStr)</c></fs>")
        let tapToKnowMore = NSLocalizedString("TapToKnowMore", comment: "Tap to know more")
        let numOfDevicesNearby = String(format: NSLocalizedString("NumOfDevicesNearby", comment: ""), rangeStr)
        nearbyLabel.accessibilityLabel = "\(numOfDevicesNearby). \(tapToKnowMore)"
        nearbyLabel.setAttributedText(markupString: nearbyMarkupString)
    }

    @IBAction func gotoBluetoothInfo(_ sender: Any) {
        let vc = SFSafariViewController(url: URL(string: "https://support.tracetogether.gov.sg/hc/en-sg/articles/360050088633-What-does-Bluetooth-exchanges-with-TraceTogether-users-mean-")!)
        present(vc, animated: true)
    }

    func traceTogetherPaused(pauseTime: Int) {
        let mainStoryboard = UIStoryboard(name: "Home", bundle: nil)
        let traceTogetherPausedVC = mainStoryboard.instantiateViewController(withIdentifier: "TraceTogetherPausedViewController") as! TraceTogetherPausedViewController
        traceTogetherPausedVC.modalPresentationStyle = .overFullScreen
        switch pauseTime {
        case 30:
            traceTogetherPausedVC.pauseTime = pauseTime
            break
        case 120:
            traceTogetherPausedVC.pauseTime = pauseTime
            break
        case 480:
            traceTogetherPausedVC.pauseTime = pauseTime
            break
        default:
            print("HomeViewController error")
            LogMessage.create(type: .Error, title: #function, details: "HomeViewController error")
        }
        present(traceTogetherPausedVC, animated: true, completion: nil)
    }

    @IBAction func pauseTracing() {
        let pauseTraceTogetherActionSheet = UIAlertController(title: "", message: "", preferredStyle: UIAlertController.Style.actionSheet)
        let titleFont = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20, weight: .bold)]
        let messageFont = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16, weight: .bold)]
        let titleAttrString = NSMutableAttributedString(string: NSLocalizedString("PauseTraceTogether", comment: "Pause TraceTogether"), attributes: titleFont as [NSAttributedString.Key: Any])
        let messageAttrString = NSMutableAttributedString(string: NSLocalizedString("TraceTogetherWillNotBeAble", comment: "We will not be able to help you note possible exposure to COVID-19 during this period ☹️"), attributes: messageFont as [NSAttributedString.Key: Any])

        pauseTraceTogetherActionSheet.setValue(titleAttrString, forKey: "attributedTitle")
        pauseTraceTogetherActionSheet.setValue(messageAttrString, forKey: "attributedMessage")
        pauseTraceTogetherActionSheet.addAction(UIAlertAction(title: NSLocalizedString("Pause30mins", comment: "Pause for 30 minutes"), style: UIAlertAction.Style.default, handler: { (_) -> Void in
            self.traceTogetherPaused(pauseTime: 30)
        }))
        pauseTraceTogetherActionSheet.addAction(UIAlertAction(title: NSLocalizedString("Pause2hrs", comment: "Pause for 2 hours"), style: UIAlertAction.Style.default, handler: { (_) -> Void in
            self.traceTogetherPaused(pauseTime: 120)
        }))
        pauseTraceTogetherActionSheet.addAction(UIAlertAction(title: NSLocalizedString("Pause8hrs", comment: "Pause for 8 hours"), style: UIAlertAction.Style.default, handler: { (_) -> Void in
            self.traceTogetherPaused(pauseTime: 480)
        }))
        pauseTraceTogetherActionSheet.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: UIAlertAction.Style.cancel, handler: nil))
        self.present(pauseTraceTogetherActionSheet, animated: true, completion: nil)
    }
}
