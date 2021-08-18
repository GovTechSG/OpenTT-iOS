//
//  SafeEntryBaseViewController.swift
//  OpenTraceTogether

import UIKit
import CoreData
import Firebase

class SafeEntryBaseViewController: UIViewController {
    var safeEntryTenant: SafeEntryTenant?
    var safeEntryCheckInOutDisplayModel = SafeEntryCheckInOutDisplayModel()
    var selectedGroupIDs: [String] = []

    var lastSafeEntrySessionWithoutCheckout: SafeEntrySession? {
        let checkInFetchRequest: NSFetchRequest<SafeEntrySession> = SafeEntrySession.fetchRequestForLastCheckInSession()

        do {
            let session = try Services.database.context.fetch(checkInFetchRequest)
            if (session.count > 0) {
                session[0].loadVenueOrCreateIfNotExist()
                return session[0]
            } else {
                return nil
            }
        } catch {
            print("Could not fetch SafeEntrySession. \(error)")
            LogMessage.create(type: .Error, title: #function, details: "Could not fetch SafeEntrySession. \(error)")
        }
        return nil
    }

    var lastSafeEntrySession: SafeEntrySession? {
        let checkInFetchRequest: NSFetchRequest<SafeEntrySession> = SafeEntrySession.fetchRequestForLastSessionWith(tenantId: safeEntryCheckInOutDisplayModel.tenantID, venueId: safeEntryCheckInOutDisplayModel.venueID)
        do {
            let session = try Services.database.context.fetch(checkInFetchRequest)
            if (session.count > 0) {
                session[0].loadVenueOrCreateIfNotExist()
                return session[0]
            } else {
                return nil
            }
        } catch {
            print("Could not fetch SafeEntrySession. \(error)")
            LogMessage.create(type: .Error, title: #function, details: "Could not fetch SafeEntrySession. \(error)")
        }
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if let selectedGroupIDs = (self.tabBarController as? SafeEntryTabBarController)?.selectedGroupIDs {
            self.selectedGroupIDs = selectedGroupIDs
        }
    }

    func updateLabels() {
        print(#function)
    }

    func updateActionButtons() {
        print(#function)
    }

    func updateFireBaseAnalytics() {
        print(#function)
    }

    func isTTOnlyError(_ error: Error) -> Bool {
        LogMessage.create(type: .Error, title: #function, details: "\(error.localizedDescription)")
        return error.localizedDescription.contains("Unauthorized. TT-only location. No group check-in/check-out.")
    }

    func invokeCheckOutAPI(_ sender: LoadingButton, completion: @escaping (_ success: Bool) -> Void) {
        sender.showLoading()
        
        //Handle internet
        if !InternetConnectionManager.isConnectedToNetwork() {
            sender.hideLoading()
            let retryAction = UIAlertAction(title: NSLocalizedString("Retry", comment: "Retry"), style: .default, handler: { _ in
                self.invokeCheckOutAPI(sender, completion: completion)
            })
            SafeEntryUtils.displayErrorAlertNoInternetController(vc: self, customErrMsgTitle: NSLocalizedString("UnableToCheckOut", comment: "Unable to check out"), withCustomRetryAction: retryAction)
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate, let reachability = appDelegate.reachability {
                LogMessage.create(type: .Error, title: #function, details: reachability.connection.description)
            }
            return
        }
        
        // Fire Check Out API - PLEASE CHECK SAFEENTRYACTIONTYPE is correct
        let unmaskedGroupIDs = (try? SecureStore.getUnmaskedIDs(maskedIDs: lastSafeEntrySessionWithoutCheckout?.groupIDs ?? [])) ?? []
        Services.safeEntryAPI.postSEEntry(safeEntryTenant: SafeEntryTenant(fromSafeSentrySession: lastSafeEntrySessionWithoutCheckout), groupIDs: unmaskedGroupIDs, actionType: SafeEntryActionType.checkout.rawValue) {[weak sender] (responseDict, err) in
            // Reenable buttons and hide loading indicator
            sender?.hideLoading()
            
            //Handle error
            guard let responseDict = responseDict else {
                LogMessage.create(type: .Error, title: #function, details: "postSEEntry error: \(err?.localizedDescription ?? "Null")")
                if err != nil, self.isTTOnlyError(err!) {
                    self.handleTTOnlyError(sender, completion: completion)
                    return
                }
                SafeEntryUtils.displayErrorAlertController(vc: self, customErrMsgTitle: NSLocalizedString("SafeEntryTemporarilyUnavailableTitle", comment: "SafeEntry QR is temporarily unavailable"), customErrMsg: NSLocalizedString("SafeEntryOtherMethodsMessage", comment: "Consider using other methods to check in/out"))
                return
            }
            
            if responseDict["status"] == "SUCCESS" {
                guard let validTimestamp = responseDict["timeStamp"] else { return }
                guard let currentCheckOutDate = SafeEntryUtils.convertRemoteTimestampToDateObject(dateString: validTimestamp) else { return }
                guard let currentVenueName = self.lastSafeEntrySessionWithoutCheckout?.venueName else { return }
                
                self.safeEntryCheckInOutDisplayModel.CHECKOUTDATE = SafeEntryUtils.getDateStringForCheckInOutViewDisplay(currentCheckOutDate)
                self.safeEntryCheckInOutDisplayModel.CHECKOUTTIME = SafeEntryUtils.getTimeStringForCheckInOutViewDisplay(currentCheckOutDate)
                self.safeEntryCheckInOutDisplayModel.VIEWEDCHECKOUTPASS = true
                self.safeEntryCheckInOutDisplayModel.VENUENAME = SafeEntryUtils.formatSETenantVenueDisplay(self.lastSafeEntrySessionWithoutCheckout?.tenantName, currentVenueName)
                self.safeEntryCheckInOutDisplayModel.NUMBEROFPERONCHECKING = (self.lastSafeEntrySessionWithoutCheckout?.groupIDs?.count ?? 0) + 1
                self.safeEntryCheckInOutDisplayModel.tenantID = self.lastSafeEntrySessionWithoutCheckout?.tenantId ?? ""
                self.safeEntryCheckInOutDisplayModel.venueID = self.lastSafeEntrySessionWithoutCheckout?.venueId ?? ""
                
                self.updateLabels()
                
                if let validLastSafeEntrySession = self.lastSafeEntrySessionWithoutCheckout {
                    let sessionUpdate = validLastSafeEntrySession as NSObject
                    sessionUpdate.setValue(currentCheckOutDate, forKey: "checkOutDate")
                }
                
                do {
                    try Services.database.context.save()
                } catch {
                    print("Could not update SafeEntrySession. \(error)")
                    LogMessage.create(type: .Error, title: #function, details: "Could not update SafeEntrySession. \(error)")
                }
                completion(true)
                return
            }
            print("if this is printed means there is an error but no Error object")
            LogMessage.create(type: .Error, title: #function, details: "There is an error but no Error object")
        }
    }

    func checkInUserToLocation(_ sender: Any? = nil, completion: @escaping (_ success: Bool) -> Void) {
        //Check internet availability, show 'retry'
        if !InternetConnectionManager.isConnectedToNetwork() {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate, let reachability = appDelegate.reachability {
                LogMessage.create(type: .Error, title: #function, details: reachability.connection.description)
            }
            let retryAction = UIAlertAction(title: NSLocalizedString("Retry", comment: "Retry"), style: .default, handler: { _ in
                self.checkInUserToLocation(sender, completion: completion)
            })
            let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: { _ in
                completion(false)
            })
            SafeEntryUtils.displayErrorAlertNoInternetController(vc: self, customErrMsgTitle: NSLocalizedString("UnableToCheckIn", comment: "Unable to check in"), withCustomRetryAction: retryAction, cancelAction: cancelAction)
            return
        }

        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: { _ in
            completion(false)
            self.dismiss(animated: false, completion: nil)
        })

        //Display alert when tenant missing.
        guard let safeEntryTenant = safeEntryTenant else {
            LogMessage.create(type: .Error, title: #function, details: "safeEntryTenant mismatch")
            SafeEntryUtils.displayErrorAlertController(vc: self, customErrMsgTitle: NSLocalizedString("SafeEntryTemporarilyUnavailableTitle", comment: "SafeEntry QR is temporarily unavailable"), customErrMsg: NSLocalizedString("SafeEntryOtherMethodsMessage", comment: "Consider using other methods to check in/out"), withCustomCancelAction: cancelAction)
            completion(false)
            return
        }

        // Fire Check In API - PLEASE CHECK SAFEENTRYACTIONTYPE is correct
        let unmaskedGroupIDs = (try? SecureStore.getUnmaskedIDs(maskedIDs: self.selectedGroupIDs)) ?? []
        SafeEntryAPIs.postSEEntry(safeEntryTenant: safeEntryTenant, groupIDs: unmaskedGroupIDs, actionType: SafeEntryActionType.checkin.rawValue) {[weak self] (responseDict, err) in
            guard let self = self else {
                print("Error")
                LogMessage.create(type: .Error, title: #function, details: "postSEEntry missing self")
                completion(false)
                return
            }

            //Handle error
            guard let responseDict = responseDict else {
                LogMessage.create(type: .Error, title: #function, details: "postSEEntry \(err?.localizedDescription ?? "Null error")")
                if err != nil, self.isTTOnlyError(err!) {
                    self.handleTTOnlyError(sender, completion: completion)
                    return
                }
                SafeEntryUtils.displayErrorAlertController(vc: self, customErrMsgTitle: NSLocalizedString("SafeEntryTemporarilyUnavailableTitle", comment: "SafeEntry QR is temporarily unavailable"), customErrMsg: NSLocalizedString("SafeEntryOtherMethodsMessage", comment: "Consider using other methods to check in/out"), withCustomCancelAction: cancelAction)
                return
            }

            //Handle success
            if responseDict["status"] == "SUCCESS" {
                guard let validTimestamp = responseDict["timeStamp"] else { return }
                guard let checkInDate = SafeEntryUtils.convertRemoteTimestampToDateObject(dateString: validTimestamp) else { return }
                var safeEntrySession = SafeEntrySessionRecord(from: safeEntryTenant, checkInDate: checkInDate)
                safeEntrySession.groupIDs = self.selectedGroupIDs
                safeEntrySession.saveToCoreData()
                print(safeEntrySession)
                self.updateVenueNamesIfRequired(safeEntrySession)

                let tenantName = safeEntryTenant.tenantName
                let venueName = safeEntryTenant.venueName

                self.safeEntryCheckInOutDisplayModel.VENUENAME = SafeEntryUtils.formatSETenantVenueDisplay(tenantName, venueName)
                self.safeEntryCheckInOutDisplayModel.CHECKINDATE = SafeEntryUtils.getDateStringForCheckInOutViewDisplay(checkInDate)
                self.safeEntryCheckInOutDisplayModel.CHECKINTIME = SafeEntryUtils.getTimeStringForCheckInOutViewDisplay(checkInDate)
                self.safeEntryCheckInOutDisplayModel.VIEWEDCHECKINPASS = true
                self.safeEntryCheckInOutDisplayModel.NUMBEROFPERONCHECKING = self.selectedGroupIDs.count + 1

                self.safeEntryCheckInOutDisplayModel.tenantID = safeEntryTenant.tenantId ?? ""
                self.safeEntryCheckInOutDisplayModel.venueID = safeEntryTenant.venueId ?? ""

                DispatchQueue.main.async {
                    completion(true)
                    self.performSegue(withIdentifier: "showCheckInOut", sender: self)
                }
                return
            }
            print("if this is printed means there is an error but no Error object")
            LogMessage.create(type: .Error, title: #function, details: "postSEEntry: There is an error but no Error object")
        }
    }

    func handleTTOnlyError(_ sender: Any?, completion: @escaping (_ success: Bool) -> Void) {
        let okAction = UIAlertAction(title: NSLocalizedString("OKCheckInForMyself", comment: "OK, Check in for myself"), style: .default, handler: {[weak self] _ in
            self?.selectedGroupIDs = []
            self?.checkInUserToLocation(sender, completion: completion)
            return
        })
        SafeEntryUtils.displayErrorAlertController(vc: self, customErrMsgTitle: NSLocalizedString("TTOnlyErrorTitle", comment: "Oops! This venue does not allow Group check in. "), customErrMsg: NSLocalizedString("TTOnlyErrorMessage", comment: "Your family needs to check in with their own TraceTogether device. This ensures that all visitors have TraceTogether activated, to better protect you in crowded places."), withCustomCancelAction: okAction)
    }

    private func updateVenueNamesIfRequired(_ sessionRecord: SafeEntrySessionRecord) {
        let checkInFetchRequest: NSFetchRequest<Venue> = Venue.fetchRequestForSessionRecord(sessionRecord)
        var favoriteData = [Venue]()
        favoriteData = (try? Services.database.context.fetch(checkInFetchRequest)) ?? []
        if favoriteData.isEmpty == false {
            let venue = favoriteData[0]
            venue.tenantName = sessionRecord.tenantName?.uppercased()
            venue.address = sessionRecord.address
            venue.name = sessionRecord.venueName?.uppercased()
            venue.postalCode = sessionRecord.postalCode
            Services.database.save()
        }
    }
}
