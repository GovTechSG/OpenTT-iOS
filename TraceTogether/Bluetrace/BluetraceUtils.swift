//
//  BluetraceUtils.swift
//  OpenTraceTogether

import UIKit
import CoreData
import Foundation
import CoreBluetooth

class BluetraceUtils {
    static func managerStateToString(_ state: CBManagerState) -> String {
        switch state {
        case .poweredOff:
            return "poweredOff"
        case .poweredOn:
            return "poweredOn"
        case .resetting:
            return "resetting"
        case .unauthorized:
            return "unauthorized"
        case .unknown:
            return "unknown"
        case .unsupported:
            return "unsupported"
        default:
            return "unknown"
        }
    }

    static func peripheralStateToString(_ state: CBPeripheralState) -> String {
        switch state {
        case .disconnected:
            return "disconnected"
        case .connecting:
            return "connecting"
        case .connected:
            return "connected"
        case .disconnecting:
            return "disconnecting"
        default:
            return "unknown"
        }
    }
}
