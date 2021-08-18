//
//  BluetraceV2.swift
//  OpenTraceTogether

import Foundation

struct V2Peripheral: PeripheralProtocol {
    static func generateAndCacheAdvtPayload() {
        advtPayload = PeripheralCharacteristicsDataV2(mp: DeviceIdentifier.modelName, id: TempIDManager.shared.getTempID(), o: BluetraceConfig.OrgID, v: 2)
    }

    func prepareReadRequestData() -> Data? {
        TempIDManager.shared.updateTempIDIfNecessary()
        return V2Peripheral.advtPayloadData
    }

    func processWriteRequestDataReceived(dataWritten: Data) -> Record? {
        do {
            let dataFromCentral = try JSONDecoder().decode(CentralWriteDataV2.self, from: dataWritten)
            #if DEBUG
            print("dataFromCentral:\(dataFromCentral)")
            #endif
            let encounter = EncounterRecord(from: dataFromCentral)
            return encounter
        } catch {
            let debugMessage = "Error: \(error). encryptedCharacteristicValue is \(dataWritten)"
            LogMessage.create(type: .Error, title: #function, details: "Error: \(error)", debugMessage: debugMessage)
        }
        return nil
    }
}

struct V2Central: CentralProtocol {
    func prepareWriteRequestData(rssi: Double) -> Data? {
        TempIDManager.shared.updateTempIDIfNecessary()
        do {
            let dataToWrite = CentralWriteDataV2(
                mc: DeviceIdentifier.modelName,
                rs: rssi,
                id: TempIDManager.shared.getTempID(),
                o: BluetraceConfig.OrgID,
                v: 2)
            let encodedData = try JSONEncoder().encode(dataToWrite)
            return encodedData
        } catch {
            LogMessage.create(type: .Error, title: #function, details: "Error: \(error)", debugMessage: "Error: \(error)")
        }
        return nil
    }

    func processReadRequestDataReceived(scannedPeriEncounter: EncounterRecord, characteristicValue: Data) -> EncounterRecord? {
        do {
            let peripheralCharData = try JSONDecoder().decode(PeripheralCharacteristicsDataV2.self, from: characteristicValue)
            var encounterStruct = scannedPeriEncounter

            encounterStruct.msg = peripheralCharData.id
            encounterStruct.update(modelP: peripheralCharData.mp)
            encounterStruct.org = peripheralCharData.o
            encounterStruct.v = peripheralCharData.v

            return encounterStruct

        } catch {
            let debugMessage = "Error: \(error). characteristicValue is \(characteristicValue)"
            LogMessage.create(type: .Error, title: #function, details: "Error: \(error).", debugMessage: debugMessage)
        }
        return nil
    }

}

extension V2Peripheral {
    static var advtPayload: PeripheralCharacteristicsDataV2? {
        get {
            if let savedAdvtPayload = advtPayloadData {
                return try? JSONDecoder().decode(PeripheralCharacteristicsDataV2.self, from: savedAdvtPayload)
            } else {
                LogMessage.create(type: .Error, title: #function, details: "Could not decode UserDefaults value of v2AdvtPayload", debugMessage: "Could not decode UserDefaults value of v2AdvtPayload")

                return nil
            }
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(encoded, forKey: "v2AdvtPayload")
            } else {
                LogMessage.create(type: .Error, title: #function, details: "Could not encode advtPayload to v2AdvtPayload", debugMessage: "Could not encode advtPayload to v2AdvtPayload")

            }
        }
    }
    static var advtPayloadData: Data? {
        get {
            return UserDefaults.standard.object(forKey: "v2AdvtPayload") as? Data
        }
    }
}
