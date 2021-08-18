//
//  BluetraceV3.swift
//  OpenTraceTogether

import Foundation

struct V3Peripheral: PeripheralProtocol {

    func prepareReadRequestData() -> Data? {
        TempIDManager.shared.updateTempIDIfNecessary()
        let dataBytes = Data(base64Encoded: TempIDManager.shared.getShortTempID(), options: Data.Base64DecodingOptions(rawValue: 0))
        return dataBytes
    }

    func processWriteRequestDataReceived(dataWritten: Data) -> Record? {
        let v3Encounter = V3EncounterRecord(msg: dataWritten.base64EncodedString(), role: "P" )

        return v3Encounter
    }
}

struct V3Central: CentralProtocol {
    func prepareWriteRequestData(rssi: Double) -> Data? {
        return nil
    }

    func processReadRequestDataReceived(scannedPeriEncounter: EncounterRecord, characteristicValue: Data) -> EncounterRecord? {
        return nil
    }

}

extension V3Peripheral {

    static var fixedTempID: Data? {
        get {
            UserDefaults.standard.object(forKey: "fixedTempID") as? Data
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "fixedTempID")
        }
    }
}
