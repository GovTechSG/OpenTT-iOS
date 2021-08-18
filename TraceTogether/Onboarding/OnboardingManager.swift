//
//  OnboardingManager.swift
//  OpenTraceTogether

import Foundation
import FirebaseAuth

class OnboardingManager {
    static let shared = OnboardingManager()
    func returnCurrentViewController() -> UIViewController {

        // delete old userdefaults
        UserDefaults.standard.removeObject(forKey: "TEMP_ID")
        UserDefaults.standard.removeObject(forKey: "TEMP_IDS_ARRAY")
        UserDefaults.standard.removeObject(forKey: "ADVT_DATA")
        UserDefaults.standard.removeObject(forKey: "BATCH_TEMPID_EXPIRY")
        UserDefaults.standard.removeObject(forKey: "VALID_TEMPID_EXPIRY")

        var hasCurrentUser = FirebaseAPIs.currentUserId != nil
        let hasTtId = UserDefaults.standard.string(forKey: "ttId") != nil

        if hasCurrentUser && !completedIWantToHelp {
            // If there is a Firebase user but no completedIWantToHelp in user defaults, means the Firebase user was loaded from keychain
            try? Auth.auth().signOut()
            hasCurrentUser = false
        }
        if hasCurrentUser && !hasTtId && !hasViewedLoveLetter { // the hasViewedLoveLetter condition is to differentiate between new users who have completed mobile phone but not ID verification
            let storyboard = UIStoryboard(name: "ReOnboarding", bundle: nil)
            let vc = storyboard.instantiateInitialViewController() as! ReonboardingWhatsNewViewController
            vc.showReonboarding = true
            return vc
        } else if !completedIWantToHelp {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "intro")
            return vc
        } else if !hasCurrentUser {
            hasConsented = false
            allowedBluetoothPermissions = false
            UserDefaults.standard.removeObject(forKey: "ttId")
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "phoneNumber")
            return vc
        } else if FormRegisterPassportProfileController().tempPassportData != nil {
            if !allowedBluetoothPermissions {
                let storyboard = UIStoryboard(name: "AllowPermission", bundle: nil)
                let vc = storyboard.instantiateInitialViewController()
                return vc!
            } else {
                let storyboard = UIStoryboard(name: "PassportHolding", bundle: nil)
                let vc = storyboard.instantiateInitialViewController()
                return vc!
            }
        } else if !hasTtId {
            let storyboard = UIStoryboard(name: "ProfileSelection", bundle: nil)
            let vc = storyboard.instantiateInitialViewController()
            return vc!
        } else if !allowedBluetoothPermissions {
            let storyboard = UIStoryboard(name: "AllowPermission", bundle: nil)
            let vc = storyboard.instantiateInitialViewController()
            return vc!
        } else {
            // latestVersionNumber is the latest version that user viewed whats new or registered on
            let latestVersionNumber = VersionNumberHelper.appVersionOnViewWhatsNew ?? VersionNumberHelper.appVersionOnRegistration ?? "0"
            if latestVersionNumber.isVersionLowerThan("2.1") {
                let storyboard = UIStoryboard(name: "ReOnboarding", bundle: nil)
                let vc = storyboard.instantiateInitialViewController() as! ReonboardingWhatsNewViewController
                vc.showReonboarding = false
                return vc
            } else {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "main")
                return vc
            }
        }
    }

    func showAlertAndStartOver(_ controller: UIViewController) {
        LogMessage.create(type: .Info, title: "showAlertAndStartOver")
        controller.showAlertWithMessage(NSLocalizedString("MissingUserID", comment: "We found a small bug 🐛"), message: NSLocalizedString("StartOver", comment: "Please enter your details and try again."), completion: { [weak self](_) -> Void in
            self?.startOver()
        })
    }

    func startOver() {
        LogMessage.create(type: .Info, title: "startOver")
        try? Auth.auth().signOut()
        UserDefaults.standard.removeObject(forKey: "ttId")
        try? SecureStore.deleteCredentials(service: "nricService", account: "id")
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let navController = appDelegate.window!.rootViewController! as! UINavigationController
        let vc =  OnboardingManager.shared.returnCurrentViewController()
        navController.setViewControllers([vc], animated: false)
    }

}

extension OnboardingManager {
    var passportVerificationRequired: Bool {
        if SafeEntryUtils.isPassportUser() && UserDefaults.standard.bool(forKey: "PassportVerificationStatus") == false {
            return true
        }
        return false
    }

    var hasCurrentUser: Bool {
        get {
            return FirebaseAPIs.currentUserId != nil
        }
    }

    var hasTtId: Bool {
        get {
            return UserDefaults.standard.string(forKey: "ttId") != nil
        }
    }

    var hasUserID: Bool {
        get {
            do {
                let userIdValue = try SecureStore.readCredentials(service: "nricService", accountName: "id").password
                return !userIdValue.isEmpty
            } catch {
                return false
            }
        }
    }

    // added in v2.0
    var hasViewedLoveLetter: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "hasViewedLoveLetter")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "hasViewedLoveLetter")
        }
    }
    // present from v1.0
    var completedIWantToHelp: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "completedIWantToHelp")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "completedIWantToHelp")
        }
    }
    // present from v1.0
    var hasConsented: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "hasConsented")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "hasConsented")
        }
    }
    // present from v1.0
    var allowedBluetoothPermissions: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "allowedPermissions")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "allowedPermissions")
        }
    }
}
