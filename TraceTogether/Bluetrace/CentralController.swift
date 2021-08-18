//
//  CentralController.swift
//  OpenTraceTogether

import Foundation
import CoreData
import CoreBluetooth
import UIKit

struct CentralWriteDataV2: Codable {
    var mc: String // phone model of central
    var rs: Double
    var id: String // tempID
    var o: String
    var v: Int
}

class CentralController: NSObject {
    enum CentralError: Error {
        case centralAlreadyOn
        case centralAlreadyOff
    }
    var centralDidUpdateStateCallback: ((CBManagerState) -> Void)?
    var characteristicDidReadValue: ((EncounterRecord) -> Void)?
    private let restoreIdentifierKey = "xxx.xxx.xxx.xxx"
    private var central: CBCentralManager?
    private var recoveredPeripherals: [CBPeripheral] = []
    private var queue: DispatchQueue

    // This dict is to keep track of discovered android devices, so that i do not connect to the same android device multiple times within the same BluetraceConfig.CentralScanInterval
    private var discoveredAndroidPeriManufacturerToUUIDMap = [Data: UUID]()

    // This dict has 2 purpose
    // 1. To store all the EncounterRecord, because the RSSI and TxPower is gotten at the didDiscoverPeripheral delegate, but the characterstic value is gotten at didUpdateValueForCharacteristic delegate
    // 2. Use to check for duplicated iphones peripheral being discovered, so that i dont connect to the same iphone again in the same scan window
    private var scannedPeripherals = [UUID: (peripheral: CBPeripheral, encounter: EncounterRecord)]() // stores the peripherals encountered within one scan interval
    var timerForScanning: Timer?

    public init(queue: DispatchQueue) {
        self.queue = queue
        super.init()
    }

    func turnOn() {
        LogMessage.create(type: .Info, title: #function, details: "central state: \(String(describing: central?.state))", debugMessage: "CC requested to be turnOn")
        guard central == nil else {
            return
        }
        central = CBCentralManager(delegate: self, queue: self.queue, options: [CBCentralManagerOptionRestoreIdentifierKey: restoreIdentifierKey])
    }

    func turnOff() {
        LogMessage.create(type: .Info, title: #function, details: "central state: \(String(describing: central?.state))", debugMessage: "CC turnOff")
        guard central != nil else {
            return
        }
        central?.stopScan()
        central = nil
    }

    public func getState() -> CBManagerState? {
        return central?.state
    }

    #warning("Unused method")
    public func getDiscoveredPeripheralsCount() -> Int {
        let COUNT_NOT_FOUND = -1
        let fetchRequest = NSFetchRequest<Encounter>(entityName: "Encounter")
        let sortByDate = NSSortDescriptor(key: "timestamp", ascending: false)
        fetchRequest.sortDescriptors = [sortByDate]
        let fetchedResultsController = NSFetchedResultsController<Encounter>(fetchRequest: fetchRequest, managedObjectContext: Services.database.context, sectionNameKeyPath: nil, cacheName: nil)

        do {
            try fetchedResultsController.performFetch()
            return fetchedResultsController.fetchedObjects?.count ?? COUNT_NOT_FOUND
        } catch let error as NSError {
            print("Could not perform fetch. \(error), \(error.userInfo)")
            LogMessage.create(type: .Error, title: #function, details: "Could not perform fetch. \(error.localizedDescription)")
            return COUNT_NOT_FOUND
        }
    }
}

extension CentralController: CBCentralManagerDelegate {

    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        LogMessage.create(type: .Info, title: #function, details: [:], collectable: true)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        centralDidUpdateStateCallback?(central.state)
        switch central.state {
        case .poweredOn:
            DispatchQueue.main.async {
                //make sure timer is invalidated before create a new one
                self.timerForScanning?.invalidate()
                self.timerForScanning = Timer.scheduledTimer(withTimeInterval: TimeInterval(BluetraceConfig.CentralScanInterval), repeats: true) { _ in
                    //modifying scannedPeripheral in main thread can cause issue because it used by other thread as well
                    self.queue.async {
                        LogMessage.create(type: .Info, title: "CC Starting a scan", details: "", collectable: false, debugMessage: "CC Starting a scan")
                        Encounter.timestamp(for: .scanningStarted)

                        // for all peripherals that are not disconnected, disconnect them
                        self.scannedPeripherals.forEach { (scannedPeri) in
                            self.central?.cancelPeripheralConnection(scannedPeri.value.peripheral)
                        }
                        // clear all peripherals, such that a new scan window can take place
                        self.scannedPeripherals = [UUID: (CBPeripheral, EncounterRecord)]()
                        self.discoveredAndroidPeriManufacturerToUUIDMap = [Data: UUID]()

                        // Using Service ID
                        self.central?.scanForPeripherals(withServices: [BluetraceConfig.BluetoothServiceID, BluetraceConfig.LiteServiceID])
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(BluetraceConfig.CentralScanDuration)) {
                        LogMessage.create(type: .Info, title: "CC Stopping a scan", details: "", collectable: false, debugMessage: "CC Stopping a scan")
                        self.central?.stopScan()
                        Encounter.timestamp(for: .scanningStopped)
                    }
                }
                self.timerForScanning?.tolerance = 0.2
                self.timerForScanning?.fire()
            }
        default:
            DispatchQueue.main.async {
                self.timerForScanning?.invalidate()
            }
        }
    }

    func handlePeripheralOfUncertainStatus(_ peripheral: CBPeripheral) {
        // If not connected to Peripheral, attempt connection and exit
        if peripheral.state != .connected {
            let debugMessage = "CC handlePeripheralOfUncertainStatus not connected"
            LogMessage.create(type: .Info, title: debugMessage, details: "", debugMessage: debugMessage)
            central?.connect(peripheral)
            return
        }
        // If don't know about Peripheral's services, discover services and exit
        if peripheral.services == nil {
            let debugMessage = "CC handlePeripheralOfUncertainStatus unknown services"
            LogMessage.create(type: .Info, title: debugMessage, details: "", debugMessage: debugMessage)
            peripheral.discoverServices([BluetraceConfig.BluetoothServiceID])
            return
        }
        // If Peripheral's services don't contain targetID, disconnect and remove, then exit.
        // If it does contain targetID, discover characteristics for service
        guard let service = peripheral.services?.first(where: { $0.uuid == BluetraceConfig.BluetoothServiceID }) else {
            let debugMessage = "CC handlePeripheralOfUncertainStatus no matching Services"
            LogMessage.create(type: .Info, title: debugMessage, details: "", debugMessage: debugMessage)
            central?.cancelPeripheralConnection(peripheral)
            return
        }
        var debugMessage = "CC handlePeripheralOfUncertainStatus discoverCharacteristics"
        LogMessage.create(type: .Info, title: debugMessage, details: "", debugMessage: debugMessage)

        peripheral.discoverCharacteristics([BluetraceConfig.BluetoothServiceID], for: service)
        // If Peripheral's service's characteristics don't contain targetID, disconnect and remove, then exit.
        // If it does contain targetID, read value for characteristic
        guard let characteristic = service.characteristics?.first(where: { $0.uuid == BluetraceConfig.BluetoothServiceID}) else {
            let debugMessage = "CC handlePeripheralOfUncertainStatus no matching Characteristics"
            LogMessage.create(type: .Info, title: "CC handlePeripheralOfUncertainStatus no matching Characteristics", details: "", debugMessage: debugMessage)
            central?.cancelPeripheralConnection(peripheral)
            return
        }
        debugMessage = "CC handlePeripheralOfUncertainStatus readValue"
        LogMessage.create(type: .Info, title: debugMessage, details: debugMessage, debugMessage: debugMessage)
        peripheral.readValue(for: characteristic)
        return
    }

    func attemptLite(advertisementData: [String: Any], rssi: NSNumber) -> Bool {
        #if DEBUG
        LogMessage.create(type: .Info, title: #function, details: [:], collectable: true)
        #endif
        guard let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] else {
            return false
        }
        guard serviceUUIDs.contains(BluetraceConfig.LiteServiceID) else {
            return false
        }
        guard let serviceDataDict = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: NSData] else {
            return false
        }
        let txPower = advertisementData[CBAdvertisementDataTxPowerLevelKey] as? NSNumber
        for (_, serviceData) in serviceDataDict {
            let serviceDataB64 = serviceData.base64EncodedString()
            LiteEncounter.create(msg: serviceDataB64, rssi: rssi, txPower: txPower)
        }
        return true
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        #if DEBUG
        let debugLogs = ["CentralState": BluetraceUtils.managerStateToString(central.state)] as AnyObject
        print("<<<<< FOUND DEVICE: \(peripheral.name ?? "NULL")")
        let debugMessage = "\(String(describing: debugLogs))"
        LogMessage.create(type: .Info, title: #function, details: "\(String(describing: debugLogs))", debugMessage: debugMessage)
        #endif
        
        let liteSucceeded = attemptLite(advertisementData: advertisementData, rssi: RSSI)
        if !liteSucceeded {
            // do regular bluetrace
            if let manuData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data {
                guard manuData.count > 2 else {
                    return
                }
                let androidIdentifierData = manuData.subdata(in: 2..<manuData.count)
                if discoveredAndroidPeriManufacturerToUUIDMap.keys.contains(androidIdentifierData) {
                    let debugMessage = "Android Peripheral \(peripheral) has been discovered already in this window, will not attempt to connect to it again"
                    #if DEBUG
                    LogMessage.create(type: .Info, title: #function, details: debugMessage, debugMessage: debugMessage)
                    #endif
                    return
                } else {
                    peripheral.delegate = self
                    discoveredAndroidPeriManufacturerToUUIDMap.updateValue(peripheral.identifier, forKey: androidIdentifierData)
                    scannedPeripherals.updateValue((peripheral, EncounterRecord(rssi: RSSI.doubleValue, txPower: advertisementData[CBAdvertisementDataTxPowerLevelKey] as? Double)), forKey: peripheral.identifier)
                    central.connect(peripheral)
                }
            } else {
                // Means not android device, i will check if the peripheral.identifier exist in the scannedPeripherals
                let debugMessage = "CBAdvertisementDataManufacturerDataKey Data not found. Peripheral is likely not android"
                LogMessage.create(type: .Info, title: #function, details: debugMessage, debugMessage: debugMessage)
                if scannedPeripherals[peripheral.identifier] == nil {
                    peripheral.delegate = self
                    scannedPeripherals.updateValue((peripheral, EncounterRecord(rssi: RSSI.doubleValue, txPower: advertisementData[CBAdvertisementDataTxPowerLevelKey] as? Double)), forKey: peripheral.identifier)
                    central.connect(peripheral)
                } else {
                    let debugMessage = "iOS Peripheral \(peripheral) has been discovered already in this window, will not attempt to connect to it again"
                    #if DEBUG
                    LogMessage.create(type: .Info, title: #function, details: debugMessage, debugMessage: debugMessage)
                    #endif
                }
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        let peripheralStateString = BluetraceUtils.peripheralStateToString(peripheral.state)
        let debugMessage = "CC didConnect peripheral. Central state: \(BluetraceUtils.managerStateToString(central.state)), Peripheral state: \(peripheralStateString)"
        LogMessage.create(type: .Info, title: #function, details: "CC didConnect peripheral. Central state: \(BluetraceUtils.managerStateToString(central.state)), Peripheral state: \(peripheralStateString)", debugMessage: debugMessage)
        peripheral.delegate = self // Maybe this line is not needed cos at didDiscover i've already set delegate to myself?
        peripheral.discoverServices([BluetraceConfig.BluetoothServiceID])
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        #if DEBUG
        let debugMessage = "CC didDisconnectPeripheral \(peripheral) , \("error: \(error?.localizedDescription ?? "")")"
        LogMessage.create(type: .Info, title: #function, details: debugMessage, debugMessage: debugMessage)
        #endif
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        let debugMessage = "CC didFailToConnect peripheral \(error != nil ? "error: \(error.debugDescription)" : "" )"
        LogMessage.create(type: .Info, title: #function, details: debugMessage, debugMessage: debugMessage)
    }
}

extension CentralController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let err = error {
            let debugMessage = "error: \(err)"
            LogMessage.create(type: .Info, title: #function, details: debugMessage, debugMessage: debugMessage)
        }
        guard let service = peripheral.services?.first(where: { $0.uuid == BluetraceConfig.BluetoothServiceID }) else { return }

        peripheral.discoverCharacteristics(BluetraceConfig.charUUIDArray, for: service)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let err = error {
            let debugMessage = "error: \(err)"
            LogMessage.create(type: .Info, title: #function, details: debugMessage, debugMessage: debugMessage)
        }

        let charV2 = service.characteristics?.first(where: { $0.uuid == BluetraceConfig.CharacteristicServiceIDv2})
        #if DEBUG
        LogMessage.create(type: .Info, title: #function, details: ["characteristic": "\(String(describing: charV2))"])
        #endif

        guard let characteristic = charV2 else { return }

        peripheral.readValue(for: characteristic)

        // Do not need to wait for a successful read before writing, because no data from the read is needed in the write
        if let currEncounter = scannedPeripherals[peripheral.identifier] {
            guard let rssi = currEncounter.encounter.rssi else {
                let debugMessage = "rssi should be present in \(currEncounter.encounter)"
                LogMessage.create(type: .Info, title: #function, details: "rssi should be present in encounter", debugMessage: debugMessage)
                return
            }
            let bluetraceImplementation = Bluetrace.getImplementation(characteristic.uuid.uuidString)

            guard let writeRequestData = bluetraceImplementation.central.prepareWriteRequestData(rssi: rssi) else {
                return
            }
            peripheral.writeValue(writeRequestData, for: characteristic, type: .withResponse)
        }

    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        #if DEBUG
        LogMessage.create(type: .Info, title: #function, details: "", debugMessage: "")
        #endif
        if error == nil {
            if let scannedPeri = scannedPeripherals[peripheral.identifier],
               let receivedCharacteristicValue = characteristic.value {
                let bluetraceImplementation = Bluetrace.getImplementation(characteristic.uuid.uuidString)

                guard let encounterStruct = bluetraceImplementation.central.processReadRequestDataReceived(scannedPeriEncounter: scannedPeri.encounter, characteristicValue: receivedCharacteristicValue) else {
                    return
                }

                scannedPeripherals.updateValue((scannedPeri.peripheral, encounterStruct), forKey: peripheral.identifier)
                encounterStruct.saveToCoreData()

            } else {
                let debugMessage = "Error: scannedPeripherals. Missing Identifier of Characteristic value"
                LogMessage.create(type: .Error, title: #function, details: debugMessage, debugMessage: debugMessage)
            }
        } else {
            let debugMessage = "Error: \(error!)"
            LogMessage.create(type: .Error, title: #function, details: "Error: \(String(describing: error?.localizedDescription))", debugMessage: debugMessage)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        #if DEBUG
        let debugMessage = "didWriteValueFor error: \(error?.localizedDescription ?? "")"
            LogMessage.create(type: .Info, title: "\(#function) writing value", details: debugMessage, debugMessage: debugMessage)
        #endif
        central?.cancelPeripheralConnection(peripheral)
    }
}
