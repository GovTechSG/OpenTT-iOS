//
//  BluetraceManager.swift
//  OpenTraceTogether

import UIKit
import CoreData
import CoreBluetooth
import FirebaseCrashlytics

class BluetraceManager {

    private var peripheralController: PeripheralController!
    private var centralController: CentralController!

    var queue: DispatchQueue!
    var bluetoothDidUpdateStateCallback: (() -> Void)?

    static let shared = BluetraceManager()

    var DEBUG_CENTRAL_ON = true
    var DEBUG_PERIPHERAL_ON = true

    private init() {
        queue = DispatchQueue(label: "BluetraceManager")
        peripheralController = PeripheralController(peripheralName: "tt ios", queue: queue)
        centralController = CentralController(queue: queue)
        centralController.centralDidUpdateStateCallback = centralDidUpdateStateCallback
        peripheralController.peripheralManagerDidUpdateStateCallback = peripheralManagerDidUpdateStateCallback
    }

    func initialConfiguration() {

    }

    func turnOn() {
        LogMessage.create(type: .Info, title: "\(#function)", details: [:], collectable: true)
        #if DEBUG
            if DEBUG_PERIPHERAL_ON {
                peripheralController.turnOn()
            }
            if DEBUG_CENTRAL_ON {
                centralController.turnOn()
            }
        #else
            peripheralController.turnOn()
            centralController.turnOn()
        #endif
    }

    func turnOff() {
        LogMessage.create(type: .Info, title: "\(#function)", details: [:], collectable: true)
        peripheralController.turnOff()
        centralController.turnOff()
    }

    func getCentralStateText() -> String {
        guard centralController.getState() != nil else {
            return "nil"
        }
        LogMessage.create(type: .Info, title: "\(#function)", details: [:], collectable: true)
        return BluetraceUtils.managerStateToString(centralController.getState()!)
    }

    func getPeripheralStateText() -> String {
        return BluetraceUtils.managerStateToString(peripheralController.getState())
    }

    func isBluetoothAuthorized() -> Bool {
        if #available(iOS 13.1, *) {
            return CBManager.authorization == .allowedAlways
        } else {
            return CBPeripheralManager.authorizationStatus() == .authorized
        }
    }

    func isBluetoothAuthorizationNotDetermined() -> Bool {
        if #available(iOS 13.1, *) {
            return CBManager.authorization == .notDetermined
        } else {
            return CBPeripheralManager.authorizationStatus() == .notDetermined
        }
    }

    // swiftlint:disable all
    func getBluetoothSetting() -> Int {
        if #available(iOS 13.1, *) {
            switch CBManager.authorization {
            case .allowedAlways:
                return 10
            case .restricted:
                return 2
            case .denied:
                return 4
            case .notDetermined:
                return 0
            @unknown default:
                return 3
            }
        } else {
            switch CBPeripheralManager.authorizationStatus() {
            case .authorized:
                return 10
            case .restricted:
                return 2
            case .denied:
                return 4
            case .notDetermined:
                return 0
            @unknown default:
                return 3
            }
        }
    }
    
    func getBluetoothStateSetting() -> Int {
        let userDefaultsState = UserDefaults.standard.integer(forKey: "bluetoothState")
        if userDefaultsState == 0 {
            // 0 is default value of BT State, so sends -1 for unknown
            return -1
        } else if userDefaultsState == -1 {
            // -1 is set by iOS side to represent off but 0 is representing as off in the backend
            return 0
        } else {
            return userDefaultsState
        }
    }

    // This may not be accurate, because even if Bluetooth will be powered on, the Bluetooth Manager state may go to Resetting or Unknown first, before landing on PoweredOn
    func isBluetoothOn() -> Bool {
        return UserDefaults.standard.integer(forKey: "bluetoothState") == 1
    }

    func isBluetoothResettingOrUnknown() -> Bool {
        return UserDefaults.standard.integer(forKey: "bluetoothState") == 4 || UserDefaults.standard.integer(forKey: "bluetoothState") == 5
    }
    
    func centralDidUpdateStateCallback(_ state: CBManagerState) {
        var stateDescription: String = ""
        switch state {
        case .poweredOff:
            stateDescription = "poweredOff"
            // we cant use 0 since it is the default value, so we use -1 to represent 0. no time!!! :3
            UserDefaults.standard.set(-1, forKey: "bluetoothState")
        case .poweredOn:
            stateDescription = "poweredOn"
            UserDefaults.standard.set(1, forKey: "bluetoothState")
        case .unauthorized:
            stateDescription = "unauthorized"
            UserDefaults.standard.set(2, forKey: "bluetoothState")
        case .unsupported:
            stateDescription = "unsupported"
            #if targetEnvironment(simulator)
            UserDefaults.standard.set(1, forKey: "bluetoothState")
            #else
            UserDefaults.standard.set(3, forKey: "bluetoothState")
            #endif
        case .resetting:
            stateDescription = "resetting"
            UserDefaults.standard.set(4, forKey: "bluetoothState")
            break
        case .unknown:
            stateDescription = "unknown"
            UserDefaults.standard.set(5, forKey: "bluetoothState")
            break
        default:
            break
        }
        //Log CBManager state to troubleshoot any bluetooth issues.
        LogMessage.create(type: .Info, title: "\(#function)", details: ["state": stateDescription], collectable: true)
        bluetoothDidUpdateStateCallback?()
        NotificationCenter.default.post(name: .bluetoothStateDidChange, object: nil)

    }

    func peripheralManagerDidUpdateStateCallback() {
        //Log Peripheral state to troubleshoot any bluetooth issues.
        LogMessage.create(type: .Info, title: "\(#function)", details: ["peripheralController state": "\(peripheralController.getState())"], collectable: true)
        bluetoothDidUpdateStateCallback?()
        NotificationCenter.default.post(name: .bluetoothStateDidChange, object: nil)
    }
    
    func toggleAdvertisement(_ state: Bool) {
        if state {
            peripheralController.turnOn()
        } else {
            peripheralController.turnOff()
        }
    }

    func toggleScanning(_ state: Bool) {
        if state {
            centralController.turnOn()
        } else {
            centralController.turnOff()
        }
    }
}
