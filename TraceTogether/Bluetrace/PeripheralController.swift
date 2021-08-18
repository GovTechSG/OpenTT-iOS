//
//  PeripheralController.swift
//  OpenTraceTogether

import CoreBluetooth

public struct PeripheralCharacteristicsDataV2: Codable {
    var mp: String // phone model of peripheral
    var id: String // tempID
    var o: String
    var v: Int
}

public class PeripheralController: NSObject {

    enum PeripheralError: Error {
        case peripheralAlreadyOn
        case peripheralAlreadyOff
    }
    var peripheralManagerDidUpdateStateCallback: (() -> Void)?
    var didUpdateState: ((String) -> Void)?
    private let restoreIdentifierKey = "com.xxx.xxx.xxx"
    private let peripheralName: String

    private var peripheral: CBPeripheralManager?
    private var characteristicV2: CBMutableCharacteristic?
    private var characteristicV3: CBMutableCharacteristic?
    private var queue: DispatchQueue

    public init(peripheralName: String, queue: DispatchQueue) {
        Logger.DLog("PC init")
        self.queue = queue
        self.peripheralName = peripheralName

        super.init()
    }

    public func turnOn() {
        guard peripheral == nil else {
            return
        }
        peripheral = CBPeripheralManager(delegate: self, queue: self.queue, options: [CBPeripheralManagerOptionRestoreIdentifierKey: restoreIdentifierKey])

    }

    public func turnOff() {
        guard peripheral != nil else {
            return
        }
        peripheral!.stopAdvertising()
        peripheral = nil
    }

    public func getState() -> CBManagerState {
        return peripheral!.state
    }

    private func start() {
        if peripheral == nil {
            Logger.DLog("Peripheral is nil")
            return
        }
        if peripheral!.isAdvertising {
            Logger.DLog("Peripheral is already advertising")
            return
        }

        var localName = peripheralName

        let service = CBMutableService(type: BluetraceConfig.BluetoothServiceID, primary: true)
        let advertisementData: [String: Any] = [CBAdvertisementDataLocalNameKey: localName,
                                                CBAdvertisementDataServiceUUIDsKey: [BluetraceConfig.BluetoothServiceID]]
        characteristicV2 = CBMutableCharacteristic(type: BluetraceConfig.CharacteristicServiceIDv2, properties: [.read, .write, .writeWithoutResponse], value: nil, permissions: [.readable, .writeable])
        characteristicV3 = CBMutableCharacteristic(type: BluetraceConfig.CharacteristicServiceIDv3, properties: [.read, .write, .writeWithoutResponse], value: nil, permissions: [.readable, .writeable])
        service.characteristics = [characteristicV2!, characteristicV3!]

        peripheral!.stopAdvertising()
        peripheral!.removeAllServices()
        peripheral!.add(service)
        peripheral!.startAdvertising(advertisementData)
    }
}

extension PeripheralController: CBPeripheralManagerDelegate {

    public func peripheralManager(_ peripheral: CBPeripheralManager,
                                  willRestoreState dict: [String: Any]) {
        LogMessage.create(type: .Info, title: #function, details: "PC willRestoreState", debugMessage: "PC willRestoreState")

        self.peripheral = peripheral
        peripheral.delegate = self
        if let services = dict[CBPeripheralManagerRestoredStateServicesKey] as? [CBMutableService] {
            for service in services {
                if let characteristics = service.characteristics {
                    for characteristic in characteristics {
                        if characteristic.uuid == BluetraceConfig.CharacteristicServiceIDv2 {
                            self.characteristicV2 = characteristic as! CBMutableCharacteristic
                        } else if characteristic.uuid == BluetraceConfig.CharacteristicServiceIDv3 {
                            self.characteristicV3 = characteristic as! CBMutableCharacteristic
                        }
                    }
                }
            }
        }
    }

    public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        let debugMessage = "PC peripheralManagerDidUpdateState. Current state: \(BluetraceUtils.managerStateToString(peripheral.state))"
        LogMessage.create(type: .Error, title: #function, details: debugMessage, debugMessage: debugMessage)

        didUpdateState?(BluetraceUtils.managerStateToString(peripheral.state))
        peripheralManagerDidUpdateStateCallback?()
        guard peripheral.state == .poweredOn else { return }
        start()
    }

    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        Logger.DLog("\(["request": request] as AnyObject)")

        let bluetraceImplementation = Bluetrace.getImplementation(request.characteristic.uuid.uuidString)

        if let readRequestData = bluetraceImplementation.peripheral.prepareReadRequestData() {
            Logger.DLog("Success - getting payload")
            request.value = readRequestData
            peripheral.respond(to: request, withResult: .success)
        } else {
            LogMessage.create(type: .Error, title: #function, details: "Error - getting payload", debugMessage: "Error - getting payload")
            peripheral.respond(to: request, withResult: .unlikelyError)
        }
    }

    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            if let receivedCharacteristicValue = request.value {
                let bluetraceImplementation = Bluetrace.getImplementation(request.characteristic.uuid.uuidString)

                guard let encounter = bluetraceImplementation.peripheral.processWriteRequestDataReceived(dataWritten: receivedCharacteristicValue) else { return }
                encounter.saveToCoreData()
            }
        }
        peripheral.respond(to: requests[0], withResult: .success)
    }
}
