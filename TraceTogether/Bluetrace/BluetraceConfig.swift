//
//  BluetraceConfig.swift
//  OpenTraceTogether

import CoreBluetooth

import Foundation

struct BluetraceConfig {
    static let BluetoothServiceID = CBUUID(string: "\(PlistHelper.getvalueFromInfoPlist(withKey: "TRACER_SVC_ID") ?? "XXX-XXX")")
    static let LiteServiceID = CBUUID(string: "\(PlistHelper.getvalueFromInfoPlist(withKey: "LITE_SVC_ID") ?? "XXX-XXX")")

    // Staging and Prod uses the same CharacteristicServiceIDv2, since BluetoothServiceID is different
    static let CharacteristicServiceIDv2 = CBUUID(string: "\(PlistHelper.getvalueFromInfoPlist(withKey: "V2_CHARACTERISTIC_ID") ?? "XX-XXX")")

    static let CharacteristicServiceIDv3 = CBUUID(string: "XX-XXX")

    static let charUUIDArray = [CharacteristicServiceIDv2]

    static let OrgID = "XX"

    static let CentralScanInterval = 60 // in seconds
    static let CentralScanDuration = 10 // in seconds

    static let TTLDays = -25

    static let BtLiteVersion = "2.0"
}
