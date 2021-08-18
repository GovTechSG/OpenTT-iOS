//
//  BarcodeModalVC.swift
//  OpenTraceTogether

import UIKit
import RSBarcodes_Swift
import AVFoundation

class BarcodeModalVC: UIViewController {

    @IBOutlet weak var greyView: UIView!
    @IBOutlet weak var nricButton: UIButton!
    @IBOutlet weak var barcodeImageView: UIImageView!

    var originalBrightness: CGFloat = 0.5
    var valueHidden = true

    /// The service we are accessing with the credentials.
    let service = "nricService"

    private var credentials = SecureStore.Credentials(username: "", password: "")

    override func viewDidLoad() {
        super.viewDidLoad()

        do {
            print("Reading credentials...")
            self.credentials = try SecureStore.readCredentials(service: service, accountName: "id")

             if let idType = UserDefaults.standard.string(forKey: "idType") {
                let profileType = NricFinChecker.checkIdType(idType: idType)
                if profileType == ProfileType.Visitor {
                    // PASSPORT
                    barcodeImageView.image = RSUnifiedCodeGenerator.shared.generateCode("PP-\(credentials.password)", machineReadableCodeObjectType: AVMetadataObject.ObjectType.code39Mod43.rawValue )
                } else {
                    barcodeImageView.image = RSUnifiedCodeGenerator.shared.generateCode("\(credentials.password)", machineReadableCodeObjectType: AVMetadataObject.ObjectType.code39.rawValue )
                }
            }

        } catch {
            if let error = error as? SecureStore.KeychainError {
                if #available(iOS 11.3, *) {
                    print(error.localizedDescription)
                    LogMessage.create(type: .Error, title: #function, details: "KeychainError: \(error.localizedDescription)")
                } else {
                    LogMessage.create(type: .Error, title: #function, details: "KeychainError: \(error)", debugMessage: "KeychainError: \(error)")
                    // Fallback on earlier versions
                }
            }
            OnboardingManager.shared.showAlertAndStartOver(self)
        }

        let secureString = NricFinMask.maskUserId(credentials.password)
        let userProfileSecureStringKey = "userprofile_secureString"
        UserDefaults.standard.set(secureString, forKey: userProfileSecureStringKey)

        nricButton.setTitle("\(secureString)", for: .normal)

        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(BarcodeModalVC.dismissTapped))
        greyView.addGestureRecognizer(tap)
        originalBrightness = UIScreen.main.brightness
        UIScreen.main.setBrightness(to: 1.0)

        // Do any additional setup after loading the view.
    }

    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    @IBAction func dismissTapped(_ sender: Any) {
        UIScreen.main.setBrightness(to: originalBrightness)
        self.dismiss(animated: true) {
            return
        }
    }
    @IBAction func toggleVisi(_ sender: UIButton) {
        valueHidden = !valueHidden
        let userProfileSecureStringKey = "userprofile_secureString"
        if let secureString = UserDefaults.standard.string(forKey: userProfileSecureStringKey) {
            if valueHidden {
                sender.isSelected = false
                sender.setTitle("\(secureString)", for: .normal)
            } else {
                sender.isSelected = true
                sender.setTitle("\(self.credentials.password)", for: .selected)
            }
        } else {
            LogMessage.create(type: .Error, title: #function, details: "Error: Secure string not found", debugMessage: "Error: Secure string not found")
        }
    }

}

extension UIScreen {

    public func setBrightness(to value: CGFloat, duration: TimeInterval = 0.3, ticksPerSecond: Double = 120) {
        let startingBrightness = UIScreen.main.brightness
        let delta = value - startingBrightness
        let totalTicks = Int(ticksPerSecond * duration)
        let changePerTick = delta / CGFloat(totalTicks)
        let delayBetweenTicks = 1 / ticksPerSecond

        let time = DispatchTime.now()

        for i in 1...totalTicks {
            DispatchQueue.main.asyncAfter(deadline: time + delayBetweenTicks * Double(i)) {
                UIScreen.main.brightness = max(min(startingBrightness + (changePerTick * CGFloat(i)), 1), 0)
            }
        }

    }
}
