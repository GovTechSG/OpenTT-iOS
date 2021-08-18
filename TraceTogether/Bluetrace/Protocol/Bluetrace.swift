//
//  Bluetrace.swift
//  OpenTraceTogether

import Foundation

struct Bluetrace {
    static let characteristicToProtocolVersionMap = [
        BluetraceConfig.CharacteristicServiceIDv2.uuidString: 2,
        BluetraceConfig.CharacteristicServiceIDv3.uuidString: 3
    ]
    static let bluetraceV2 = BluetraceProtocol(central: V2Central(), peripheral: V2Peripheral())
    static let bluetraceV3 = BluetraceProtocol(central: V3Central(), peripheral: V3Peripheral())
    static let implementations = [2: bluetraceV2, 3: bluetraceV3]

    // gets the protocol implementation via the charUUID map
    // fallbacks to V2
    static func getImplementation(_ charUUID: String) -> BluetraceProtocol {
        if let protocolVersion = Bluetrace.characteristicToProtocolVersionMap[charUUID] {
            return getImplementation(protocolVersion)
        }
        return bluetraceV2
    }

    static func getImplementation(_ protocolVersion: Int) -> BluetraceProtocol {
        if let impl = implementations[protocolVersion] {
            return impl
        }

        return bluetraceV2
    }

}
