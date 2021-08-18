//
//  QRViewController.swift
//  OpenTraceTogether

import Foundation
import AVFoundation
import UIKit

extension QRViewController: UITabBarControllerDelegate {
      func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
      return viewController != tabBarController.selectedViewController
}}

class QRViewController: SafeEntryBaseViewController {

    @IBOutlet weak var redTabbarLine: UIView!
    @IBOutlet weak var trailingProgressConstraint: NSLayoutConstraint!
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var rectToFocus: CGRect?
    var safeEntryTenants: [[String: String?]]?

    @IBOutlet weak var scanSETitleBtn: UIButton!
    @IBOutlet weak var backBtn: UIButton!
    @IBOutlet weak var howToUseView: UIView!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var declarationScrollView: UIScrollView!
    var smallSquareRect: CGRect = CGRect()

    let activityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.whiteLarge)

    let messageArray = [NSLocalizedString("seMsg1", comment: "You have no close contact with a confirmed COVID-19 case in the past 14 days *#"), NSLocalizedString("seMsg2", comment: "You're not currently under a Quarantine Order or Stay-Home Notice *"), NSLocalizedString("seMsg3", comment: "You have no fever or flu-like symptoms *"), NSLocalizedString("seMsg4", comment: "You agree to the terms and consent to the collection/use of your information for COVID-19 contact tracing")]

    var overlay = UIView()
    var groupCheckInFlowToHandleIDTab = Bool()

    override func viewDidLoad() {
        super.viewDidLoad()
        selectedGroupIDs = (self.tabBarController as! SafeEntryTabBarController).selectedGroupIDs
        setupHowToUseAction()
        scanSETitleBtn.isEnabled = false
        scanSETitleBtn.isUserInteractionEnabled = false

        if UserDefaults.standard.bool(forKey: "FavouritesTabVisited") {
            tabBarController?.tabBar.items?[1].badgeValue = nil
        } else {
            tabBarController?.tabBar.items?[1].badgeValue = NSLocalizedString("New", comment: "NEW")
            tabBarController?.tabBar.items?[1].setBadgeTextAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12.0, weight: .regular)], for: .normal)
            tabBarController?.tabBar.items?[1].badgeColor = UIColor(red: 255.0/255.0, green: 101.0/255.0, blue: 101.0/255.0, alpha: 1.0)
        }

        let fWidth = self.view.frame.size.width
        let fHeight = self.view.frame.size.height
        let squareWidth = fWidth/3*2
        let topLeft = CGPoint(x: fWidth/2-squareWidth/2, y: fHeight/2-squareWidth/2)
        let topRight = CGPoint(x: fWidth/2+squareWidth/2, y: fHeight/2-squareWidth/2)
        let bottomLeft = CGPoint(x: fWidth/2-squareWidth/2, y: fHeight/2+squareWidth/2)
        smallSquareRect = CGRect(x: topLeft.x, y: topLeft.y - fHeight / 9, width: topRight.x - topLeft.x + 5, height: bottomLeft.y - topLeft.y + 5)

        //Make terms clickable
        messageTextView.attributedText = makeBulletedAttributedString(stringList: messageArray, font: UIFont.systemFont(ofSize: 14.0), bullet: "-")

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let userOnboardedQRScanning = UserDefaults.standard.bool(forKey: "UserHasUnderstoodHowQRScanningWorks")
        if !userOnboardedQRScanning {
            showQRScanInstructions()
            return
        }

        if cameraPermissionIsDeniedOrRestricted() {
            showCameraPermssionsRequired()
            return
        }

        if captureSession == nil {
          doInitialSetup(smallSquareRect)
        }

        startScanning()

        // Set the small rect to on scan when the QR code is within the rectangle
//        doInitialSetup(smallSquareRect)

        // Create the same small square overlay here
        if !self.overlay.isDescendant(of: self.view) {
            self.overlay = createOverlay(smallSquareRect: smallSquareRect)

            self.view.addSubview(overlay)

            view.bringSubviewToFront(backBtn)
            view.bringSubviewToFront(howToUseView)
            view.bringSubviewToFront(scanSETitleBtn)
            view.bringSubviewToFront(declarationScrollView)
            view.bringSubviewToFront(redTabbarLine)

            scanSETitleBtn.titleLabel?.textAlignment = .center
            scanSETitleBtn.titleLabel?.adjustsFontSizeToFitWidth = true

            scanSETitleBtn.alpha = 1
            scanSETitleBtn.isEnabled = true
        }

        AnalyticManager.setScreenName(screenName: "SEScanQR", screenClass: "QRViewController")
    }

    func createOverlay(smallSquareRect: CGRect) -> UIView {
        // Step 1
        let overlayView = UIView(frame: self.view.frame)
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.7)

        // Step 2
        let path = CGMutablePath()
        path.addRoundedRect(in: smallSquareRect,
                            cornerWidth: 2, cornerHeight: 2)
        path.addRect(CGRect(origin: .zero, size: overlayView.frame.size))

        // Step 3
        let maskLayer = CAShapeLayer()
        maskLayer.backgroundColor = UIColor.clear.cgColor

        maskLayer.lineDashPattern = [3, 3]
        maskLayer.lineWidth = 2
        maskLayer.strokeColor = UIColor.white.cgColor

        maskLayer.path = path

        // For Swift 4.2
        maskLayer.fillRule = .evenOdd
        // Step 4
        overlayView.layer.mask = maskLayer
        overlayView.clipsToBounds = true

        return overlayView
    }

    func showQRScanInstructions() {
        UserDefaults.standard.set(true, forKey: "instructionsVisited")
        let storyboard = UIStoryboard(name: "SafeEntry", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "QRInstructionsViewController") as! UINavigationController
        vc.modalPresentationStyle = .fullScreen
        vc.modalTransitionStyle = .crossDissolve
        if groupCheckInFlowToHandleIDTab {
            UserDefaults.standard.setValue(true, forKey: "groupCheckInFlowToHandleHowToUse")
        } else {
            UserDefaults.standard.setValue(false, forKey: "groupCheckInFlowToHandleHowToUse")
        }
        self.present(vc, animated: true, completion: nil)
    }

    func showCameraPermssionsRequired() {
        self.performSegue(withIdentifier: "showCameraPermsRequiredSegue", sender: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        self.tabBarController?.delegate = self
        self.tabBarController?.tabBar.isHidden = false

        if groupCheckInFlowToHandleIDTab {
            trailingProgressConstraint.constant = (UIScreen.main.bounds.width/2)
        } else {
            trailingProgressConstraint.constant = (UIScreen.main.bounds.width/3) * 2
        }

    }

    @IBAction func returnToMainPage() {
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        self.navigationController?.dismiss(animated: true, completion: nil)
    }

    func locationOrLocationListRouter(numberOfAddress: Int) {
        if numberOfAddress == 1 {
            safeEntryTenant = SafeEntryTenant(tenantDict: self.safeEntryTenants?.first)
            checkInUserToLocation { (_) in }
        } else {
            self.performSegue(withIdentifier: "goToLocationList", sender: self)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showCheckInOut" {
            let destinationVC = segue.destination as! CheckInOutViewController
            destinationVC.safeEntryCheckInOutDisplayModel = safeEntryCheckInOutDisplayModel
        } else if segue.identifier == "goToLocationList" {
            let destinationVC = segue.destination as! SafeEntryMultipleAddressViewController
            let safeEntryTenants = self.safeEntryTenants?.map({ (tenantDict) -> SafeEntryTenant in
                return SafeEntryTenant(tenantDict: tenantDict)
            })
            destinationVC.tenants = safeEntryTenants
        }
    }

    func setupHowToUseAction() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(goToHelpView))
        tapGestureRecognizer.numberOfTapsRequired = 1
        self.howToUseView.addGestureRecognizer(tapGestureRecognizer)
    }

    @objc func goToHelpView(recognizer: UITapGestureRecognizer) {
        self.showQRScanInstructions()
    }

}
extension QRViewController {

    func cameraPermissionIsDeniedOrRestricted() -> Bool {
        if AVCaptureDevice.authorizationStatus(for: .video) ==  .denied || AVCaptureDevice.authorizationStatus(for: .video) ==  .restricted {
            return true
        } else {
            return false
        }
    }

    func stopScanning() {
        captureSession?.stopRunning()
    }

    func startScanning() {
        captureSession?.startRunning()
    }

    func scanningDidFail() {
        captureSession = nil
    }

    /// Does the initial setup for captureSession
    private func doInitialSetup(_ smallSquareRect: CGRect) {
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch let error {
            print(error)
            LogMessage.create(type: .Error, title: #function, details: error.localizedDescription, collectable: true)
            return
        }

        if (captureSession?.canAddInput(videoInput) ?? false) {
            captureSession?.addInput(videoInput)
        } else {
            scanningDidFail()
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if (captureSession?.canAddOutput(metadataOutput) ?? false) {
            captureSession?.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            scanningDidFail()
            return
        }

        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer?.frame = view.layer.bounds
        view.layer.addSublayer(videoPreviewLayer!)
    }

    func qrScanningSucceededWithCode(_ str: String ) {
        activityIndicator.center = view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)

        if str.contains("https") == false {
            // no HTTPS in QR code
            let titleMessage = NSLocalizedString("NotASafeEntryQRCodeTitle", comment: "This doesn't seem like a SafeEntry QR code")
            let errMessage = NSLocalizedString("NotASafeEntryQRCodeMessage", comment: "Ensure you are scanning a valid SafeEntry QR code.")
            let cancelAction = UIAlertAction(title: NSLocalizedString("ScanAgain", comment: "Scan again"), style: .cancel, handler: { _ in
                self.activityIndicator.stopAnimating()
                self.startScanning()
            })
            //let alert = UIAlertController(title: "An error has occurred", message: errMessage, preferredStyle: .alert)
            let alert = UIAlertController(title: titleMessage, message: errMessage, preferredStyle: .alert)
            alert.addAction(cancelAction)
            alert.preferredAction = cancelAction
            self.present(alert, animated: true)
            LogMessage.create(type: .Error, title: #function, details: "NotASafeEntryQRCode: \(str)", collectable: true)
            return
        }

        SafeEntryAPIs.getSEVenue(url: str) { (tenants, err) in
            self.activityIndicator.stopAnimating()
            var errMessage: String?
            var titleMessage: String?
            // SE URL Error
            if err != nil {
                titleMessage = NSLocalizedString("SafeEntryTemporarilyUnavailableTitle", comment: "SafeEntry QR is temporarily unavailable")
                errMessage = NSLocalizedString("SafeEntryOtherMethodsMessage", comment: "Consider using other methods to check in/out")
                LogMessage.create(type: .Error, title: #function, details: "getSEVenue error: \(err!.localizedDescription)", collectable: true)
            }
            // Non SE URL Handling
            else if tenants == nil {
                titleMessage = NSLocalizedString("NotASafeEntryQRCodeTitle", comment: "This doesn't seem like a SafeEntry QR code")
                errMessage = NSLocalizedString("NotASafeEntryQRCodeMessage", comment: "Ensure you are scanning a valid SafeEntry QR code.")
                LogMessage.create(type: .Error, title: #function, details: "Server not returning a single tenant from QR code", collectable: true)
            } else {
                AnalyticManager.logEvent(eventName: "se_scan_qr_success", param: nil)
                // Success - Dont let alert controller pop up
                self.safeEntryTenants = tenants
                self.locationOrLocationListRouter(numberOfAddress: tenants!.count)
                return
            }
            let cancelAction = UIAlertAction(title: NSLocalizedString("ScanAgain", comment: "Scan again"), style: .cancel, handler: { _ in
                self.startScanning()
            })
            let alert = UIAlertController(title: titleMessage, message: errMessage, preferredStyle: .alert)
            alert.addAction(cancelAction)
            alert.preferredAction = cancelAction
            self.present(alert, animated: true)
        }
    }

    func found(urlFound: String) {
        let retryAction = UIAlertAction(title: NSLocalizedString("Retry", comment: "Retry"), style: .default, handler: { _ in
            self.found(urlFound: urlFound)
        })
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: { _ in
            self.startScanning()
        })

        if InternetConnectionManager.isConnectedToNetwork() {
            self.qrScanningSucceededWithCode(urlFound)
        } else {
            let alert = UIAlertController(title: NSLocalizedString("UnableToCheckIn", comment: "Unable to check in"), message: NSLocalizedString("NetworkIssue", comment: "There seems to be a network issue. Check your connection and try again."), preferredStyle: .alert)
            alert.addAction(retryAction)
            alert.addAction(cancelAction)
            alert.preferredAction = retryAction
            self.present(alert, animated: true)
            LogMessage.create(type: .Error, title: #function, details: "Not connected to network", collectable: true)
        }
    }
}

extension QRViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        stopScanning()

        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else {
                return LogMessage.create(type: .Error, title: #function, details: "No readable object", collectable: true)
            }
            guard let stringValue = readableObject.stringValue else {
                return LogMessage.create(type: .Error, title: #function, details: "No readable object string value", collectable: true)
            }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(urlFound: stringValue)
            print("QR: \(stringValue)")
        }
    }
}
