//
//  BluetraceProtocol.swift

//
//  OpenTraceTogether


import Foundation

class BluetraceProtocol {
    let central: CentralProtocol
    let peripheral: PeripheralProtocol

    init(central: CentralProtocol, peripheral: PeripheralProtocol) {
        self.central = central
        self.peripheral = peripheral
    }
}

protocol Record {
//    init()
    func saveToCoreData()
}

protocol EncounterProtocol {
    var msg: String? { get set }
    var timestamp: Date? { get set }
}

protocol PeripheralProtocol {
    func prepareReadRequestData() -> Data?

    // to be used in didReceiveWrite, saved EncounterRecord
    func processWriteRequestDataReceived(dataWritten: Data) -> Record?
}

protocol CentralProtocol {
    // to be used in didDiscoverCharacteristicsFor, get Data for peripheral.writeValue
    func prepareWriteRequestData(rssi: Double) -> Data?

    func processReadRequestDataReceived(scannedPeriEncounter: EncounterRecord, characteristicValue: Data) -> EncounterRecord?
}
