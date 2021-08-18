//
//  CheckInOutViewController.swift
//  OpenTraceTogether

import Foundation
import UIKit
import CoreData

class CheckInOutViewController: SafeEntryBaseViewController {
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var numOfPaxLabel: UILabel!
    @IBOutlet weak var paxBackgroundView: UIView!
    @IBOutlet weak var baseShadowView: UIView!

    @IBOutlet weak var backToHomeButton: UIButton!
    @IBOutlet weak var checkInOutButton: LoadingButton!
    @IBOutlet weak var seCheckInOUtLabel: UILabel!
    
    @IBOutlet weak var venueName: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var savLocToFavBtn: UIButton!

    var checkin = false

    override func viewDidLoad() {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        //Remove bottom line of navBar
        self.navigationController?.navigationBar.setValue(true, forKey: "hidesShadow")
        updateActionButtons()
        updateLabels()

        createSaveLocToFavButton()

    }

    func createSaveLocToFavButton() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineBreakMode = .byWordWrapping

        guard let normalfont = UIFont(name: "Poppins-Medium", size: 15) else {
            return
        }

        let lineAttribute = [NSAttributedString.Key.underlineStyle: 1] as [NSAttributedString.Key: Any]

        let normalBtnAttributedString = NSMutableAttributedString(string: NSLocalizedString("SavLocToFav", comment: "Save this location to Favourites"), attributes: [NSAttributedString.Key.font: normalfont, NSAttributedString.Key.paragraphStyle: paragraphStyle])
        let range = (NSLocalizedString("SavLocToFav", comment: "Save this location to Favourites") as NSString).range(of: NSLocalizedString("SavLocToFavUnderline", comment: "Save this location"))
        normalBtnAttributedString.addAttributes(lineAttribute, range: range)
        savLocToFavBtn.setAttributedTitle(normalBtnAttributedString, for: .normal)

        let selectedBtnAttributedString = NSMutableAttributedString(string: NSLocalizedString("LocSavedToFav", comment: "This location is in your Favourites"), attributes: [NSAttributedString.Key.font: normalfont, NSAttributedString.Key.paragraphStyle: paragraphStyle])
        savLocToFavBtn.setAttributedTitle(selectedBtnAttributedString, for: .selected)

        savLocToFavBtn.titleLabel?.numberOfLines = 0
        savLocToFavBtn.titleLabel?.lineBreakMode = .byWordWrapping
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        #if DEBUG
        print("lastSafeEntrySession:\(String(describing: lastSafeEntrySession?.venueName)) \(String(describing: lastSafeEntrySession?.tenantName)) \(String(describing: lastSafeEntrySession?.venue?.isFavourite))")
        #endif

        if let validLastSafeEntrySession = lastSafeEntrySession {
            guard let venue = validLastSafeEntrySession.venue else { return }
            if venue.isFavourite {
                savLocToFavBtn.isSelected = venue.isFavourite
            }
        }
}

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateFireBaseAnalytics()
    }

    override func updateLabels() {
        venueName.text = safeEntryCheckInOutDisplayModel.VENUENAME
        if safeEntryCheckInOutDisplayModel.VIEWEDCHECKOUTPASS {
            dateLabel.text = safeEntryCheckInOutDisplayModel.CHECKOUTDATE
            timeLabel.text = safeEntryCheckInOutDisplayModel.CHECKOUTTIME
        } else {
            dateLabel.text = safeEntryCheckInOutDisplayModel.CHECKINDATE
            timeLabel.text = safeEntryCheckInOutDisplayModel.CHECKINTIME
        }
        numOfPaxLabel.text = "\(safeEntryCheckInOutDisplayModel.NUMBEROFPERONCHECKING)"
        let numOfPax = NSLocalizedString("NumOfPax", comment: "Number of Pax checked in =")
        numOfPaxLabel.accessibilityLabel = "\(numOfPax)  \(safeEntryCheckInOutDisplayModel.NUMBEROFPERONCHECKING)"
    }

    override func viewDidLayoutSubviews() {
        headerView.roundCorners(corners: [.topLeft, .topRight], radius: 10.0)

        contentView.roundCorners(corners: [.bottomLeft, .bottomRight], radius: 10.0)
        baseShadowView.layer.shadowColor = UIColor.black.cgColor
        baseShadowView.backgroundColor = UIColor.clear
        baseShadowView.layer.shadowOffset = CGSize(width: 0, height: 1)
        baseShadowView.layer.shadowOpacity = 0.35
        baseShadowView.layer.shadowRadius = 4.0
        baseShadowView.layer.masksToBounds =  false
    }

    @IBAction func backToHomeAction() {
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        self.navigationController?.dismiss(animated: true, completion: nil)

        guard let tabBarController = self.tabBarController as? SafeEntryTabBarController else {
            return
        }
        tabBarController.userDelegate?.popToRootViewController(animated: true)
    }

    @IBAction func checkOutAction() {
        super.invokeCheckOutAPI(checkInOutButton) {_ in
            self.updateActionButtons()
            self.updateFireBaseAnalytics()
        }
    }

    @IBAction func saveLocationToFavourites(_ sender: UIButton) {
        sender.isSelected.toggle()
        lastSafeEntrySession?.loadVenueOrCreateIfNotExist()
        lastSafeEntrySession?.venue?.setFavouriteAndSave(sender.isSelected)
    }

    override func updateActionButtons() {
        if safeEntryCheckInOutDisplayModel.VIEWEDCHECKINPASS {
            backToHomeButton.isHidden = false
            checkInOutButton.isHidden = true
            checkInView()
        } else {
            if safeEntryCheckInOutDisplayModel.VIEWEDCHECKOUTPASS {
                backToHomeButton.isHidden = false
                checkInOutButton.isHidden = true
                checkOutView()
            } else {
                backToHomeButton.isHidden = true
                checkInOutButton.isHidden = false
                checkInView()
            }
        }
    }

    override func updateFireBaseAnalytics() {
        if safeEntryCheckInOutDisplayModel.VIEWEDCHECKINPASS {
            AnalyticManager.setScreenName(screenName: "SECheckInPass", screenClass: "CheckInOutViewController")
        } else {
            if safeEntryCheckInOutDisplayModel.VIEWEDCHECKOUTPASS {
                AnalyticManager.setScreenName(screenName: "SECheckOutPass", screenClass: "CheckInOutViewController")
            } else {
                AnalyticManager.setScreenName(screenName: "SECheckInPass", screenClass: "CheckInOutViewController")
            }
        }
    }

    func checkInView() {
        seCheckInOUtLabel.text = "SafeEntry Check-in"
        headerView.backgroundColor = UIColor(hexString: "B7AC44")
        paxBackgroundView.backgroundColor = UIColor(hexString: "#B7AC44")
        paxBackgroundView.layer.masksToBounds = true
    }

    func checkOutView() {
        seCheckInOUtLabel.text = "SafeEntry Check-out"
        headerView.backgroundColor = UIColor(hexString: "FF6347")
        paxBackgroundView.backgroundColor = UIColor(hexString: "#FF6347")
        paxBackgroundView.layer.masksToBounds = true

    }
}
