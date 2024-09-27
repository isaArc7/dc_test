//
//  BluetoothManager.swift
//  MLDataCollectionApp
//
//  Created by Lai Wei on 2024-05-17.
//

import Foundation
import CoreBluetooth


enum ConnectionStatus {
    case disconnected
    case connectedToScanner
    case connectedToVehicle
}

/// Protocol to handle updates related to Bluetooth management.
///
/// This protocol includes methods to manage and respond to changes in Bluetooth connection
/// status, discovery of peripherals, and communication with peripherals.
protocol BluetoothManagerDelegate: AnyObject {
    
    /// Notifies the delegate of a change in Bluetooth connection status.
    /// - Parameter status: The new connection status.
    func bluetoothStatusChanged(status: ConnectionStatus)
    
    /// Called when a peripheral is discovered while scanning.
    /// - Parameter peripheral: The discovered peripheral.
    func didDiscoverPeripheral(_ peripheral: CBPeripheral)
    
    /// Called when a successful connection has been made to a peripheral.
    /// - Parameter peripheral: The peripheral that was connected.
    func didConnectPeripheral(_ peripheral: CBPeripheral)
    
    /// Called when an attempt to connect to a peripheral fails.
    /// - Parameters:
    ///   - peripheral: The peripheral that failed to connect.
    ///   - error: The error that occurred during connection attempt.
    func didFailToConnectPeripheral(_ peripheral: CBPeripheral, error: Error?)
    
    /// Called when a connected peripheral disconnects.
    /// - Parameters:
    ///   - peripheral: The peripheral that disconnected.
    ///   - error: The error (if any) that occurred leading to the disconnection.
    func didDisconnectPeripheral(_ peripheral: CBPeripheral, error: Error?)
}


/// `BluetoothManager` manages and handles Bluetooth operations.
/// This class encapsulates the operations related to starting and stopping Bluetooth scanning,
/// connecting and disconnecting from peripherals, and handling Bluetooth state updates.
internal class BluetoothManager: NSObject {
    
    /// The central manager that will be used to manage Bluetooth functionalities.
    var centralManager: CBCentralManager!
    
    /// The delegate responsible for handling Bluetooth status changes and peripheral interactions.
    weak var delegate: BluetoothManagerDelegate?
    
    /// The peripheral that is currently connected.
    private var connectedPeripheral: CBPeripheral?
    
    /// The characteristic used to write data to a peripheral.
    private var ecuWriteCharacteristic: CBCharacteristic?
    
    /// The characteristic used to read data from a peripheral.
    private var ecuReadCharacteristic: CBCharacteristic?
    
    /// A completion handler for sending messages, containing optional response strings and an error.
    private var sendMessageCompletion: (([String]?, Error?) -> Void)?
    
    /// A buffer to store incoming data until it is complete.
    private var responseData = Data()
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    /// Starts scanning for peripherals if Bluetooth is powered on.
    func startScanning(){
        switch centralManager.state {
        case .poweredOn:
            centralManager.scanForPeripherals(withServices: nil)
        
        case .unknown, .resetting:
          Log.warning("Bluetooth status is initializing. Retrying in 1 second...")
          DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.startScanning()
          }
            
        case .unsupported, .unauthorized, .poweredOff:
//            print("Error: Bluetooth is not available or not authorized.")
            Log.error("Bluetooth is not available or not authorized.")
//            Log.d(level: .error, msg: "Bluetooth is not available or not authorized.")
            delegate?.bluetoothStatusChanged(status: .disconnected)
        @unknown default:
            fatalError("Unhandled Bluetooth state.")
        }
    }
    
    /// Stops scanning for Bluetooth peripherals if currently scanning.
    func stopScanning(){
        if centralManager.isScanning {
            centralManager.stopScan()
        }
    }
    
    /// Attempts to connect to a given peripheral.
    /// - Parameter peripheral: The peripheral to connect to.
    func connect(to peripheral: CBPeripheral){
        centralManager.connect(peripheral)
        stopScanning()
    }
    
    /// Disconnects from a given peripheral.
    /// - Parameter peripheral: The peripheral to disconnect from.
    func disconnect(from peripheral: CBPeripheral) {
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    /// Sends a command to the connected peripheral.
    /// - Parameters:
    ///   - command: The command string to send.
    ///   - timeout: The timeout for sending the command.
    ///   - completion: A completion handler that returns the result of the command as a success or failure.
    func sendCommand(_ command: String, timeout: TimeInterval, completion: @escaping (Result<[String], Error>) -> Void) {
        guard sendMessageCompletion == nil else {
            completion(.failure(BluetoothManagerError.sendingMessagesInProgress))
            return
        }
        
        guard let connectedPeripheral = connectedPeripheral,
              let characteristic = ecuWriteCharacteristic,
              let data = "\(command)\r".data(using: .utf8) else {
//            print("Error: \(BluetoothManagerError.missingPeripheralOrCharacteristic.description)")
            Log.error("\(BluetoothManagerError.missingPeripheralOrCharacteristic.description)")
//            Log.d(level: .error, msg: BluetoothManagerError.missingPeripheralOrCharacteristic.description)
            completion(.failure(BluetoothManagerError.missingPeripheralOrCharacteristic))
            return
        }
        
        sendMessageCompletion = { response, error in
            self.sendMessageCompletion = nil
            if let error = error {
                completion(.failure(error))
            } else if let response = response {
                completion(.success(response))
            } else {
                completion(.failure(BluetoothManagerError.unknownError))
            }
        }
        
        connectedPeripheral.writeValue(data, for: characteristic, type: .withResponse)
        
        // Set up a timeout to handle the case where no response is received
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            if self.sendMessageCompletion != nil {
                self.sendMessageCompletion = nil
                completion(.failure(BluetoothManagerError.timeout))
            }
        }
    }
    
    
    
    /// Processes the received data from the peripheral.
    /// - Parameters:
    ///   - data: The data received from the peripheral.
    ///   - completion: The completion handler that processes the received data.
    func processResponseData(_ data: Data, completion _: (([String]?, Error?) -> Void)?) {
        responseData.append(data)
        
        guard let string = String(data: responseData, encoding: .utf8) else {
            responseData.removeAll()
            return
        }
        
        if string.contains(">") {
            var lines = string
                .components(separatedBy: .newlines)
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            
            // remove the last line
            lines.removeLast()
            
            if sendMessageCompletion != nil {
                if lines[0].uppercased().contains("NO DATA") {
                    sendMessageCompletion?(nil, BluetoothManagerError.noData)
                } else {
                    sendMessageCompletion?(lines, nil)
                }
            }
            responseData.removeAll()
        }
    }
}

/// Extension of BluetoothManager to handle central and peripheral delegate methods.
extension BluetoothManager: CBCentralManagerDelegate, CBPeripheralDelegate {
    
    // MARK: Central Manager Delegate Methods
    
    /// Responds to updates in the central manager's state.
    /// Logs the new state and handles any necessary changes in app behavior.
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch centralManager.state {
        case .poweredOn:
            Log.info("Bluetooth is powered on.")
//            print("Info: Bluetooth is powered on.")
//            Log.d(level: .info, msg: "Bluetooth is powered on.")
            
        case .unknown, .resetting:
            Log.warning("Bluetooth status is initializing. Please wait...")
//            print("Warning: Bluetooth status is initializing. Please wait...")
//            Log.d(level: .warning, msg: "Bluetooth status is initializing. Please wait...")
            
        case .unsupported, .unauthorized, .poweredOff:
            Log.error("Bluetooth is not available or not authorized.")
//            print("Error: Bluetooth is not available or not authorized.")
//            Log.d(level: .error, msg: "Bluetooth is not available or not authorized.")
            delegate?.bluetoothStatusChanged(status: .disconnected)
        @unknown default:
            fatalError("Unhandled Bluetooth state.")
        }
    }
    
    /// Called when a peripheral is discovered.
    /// Notifies the delegate with the discovered peripheral.
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        delegate?.didDiscoverPeripheral(peripheral)
    }
    
    /// Called when a connection is successfully made with a peripheral.
    /// Sets up the peripheral to discover available services.
     func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectedPeripheral = peripheral
        connectedPeripheral?.delegate = self
        connectedPeripheral?.discoverServices(nil)
        
    }
    
    /// Called when the central manager fails to connect to a peripheral.
    /// Notifies the delegate of the failure.
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        connectedPeripheral = nil
        delegate?.bluetoothStatusChanged(status: .disconnected)
        delegate?.didFailToConnectPeripheral(peripheral, error: error)
    }
    
    /// Called when a peripheral disconnects.
    /// Notifies the delegate of the disconnection.
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectedPeripheral = nil
        delegate?.bluetoothStatusChanged(status: .disconnected)
        delegate?.didDisconnectPeripheral(peripheral, error: error)
    }
    
    // MARK: Peripheral Delegate Methods
    
    /// Called when services are discovered on a peripheral.
    /// Initiates discovery of characteristics for each service found.
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else {
            return
        }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    /// Called when characteristics for a service are discovered.
    /// Sets notifications for characteristics that support it and handles them accordingly.
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics, !characteristics.isEmpty else {
            return
        }
        for characteristic in characteristics {
            if characteristic.properties.contains(.notify){
                peripheral.setNotifyValue(true, for: characteristic)
            }
            handleCharacteristic(characteristic, for: service)
        }
        if let read = ecuReadCharacteristic, let write = ecuWriteCharacteristic {
            delegate?.bluetoothStatusChanged(status: .connectedToScanner)
            delegate?.didConnectPeripheral(peripheral)
        }
    }
    
    /// Handles characteristics discovered in a service, setting up read and write characteristics.
    private func handleCharacteristic(_ characteristic: CBCharacteristic, for service: CBService) {
        switch service.uuid.uuidString {
        case "FFF0":
            if characteristic.uuid == CBUUID(string: "FFF1") {
                ecuReadCharacteristic = characteristic
            } else if characteristic.uuid == CBUUID(string: "FFF2") {
                ecuWriteCharacteristic = characteristic
            }
            //TODO: Add additional cases for other service UUIDs
            
        default:
            // Handle unknown services or log them
            print("Unhandled Service UUID: \(service.uuid)")
        }
    }
    
    /// Called when a characteristic's value is updated.
    /// Processes the received data or logs errors if the update failed.
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            Log.error("\(error.localizedDescription)")
//            print("Error: \(error.localizedDescription)")
//            Log.d(level: .error, msg: error.localizedDescription)
            return
        }
        
        guard let responseValue = characteristic.value else {
            Log.error("\(BluetoothManagerError.noResponse.description)")
//            print("Error: \(BluetoothManagerError.noResponse.description)")
//            Log.d(level: .error, msg: BluetoothManagerError.noResponse.description)
            return
        }
        // handle the response
        switch characteristic {
        case ecuReadCharacteristic:
            processResponseData(responseValue, completion: sendMessageCompletion)
        default:
            guard let responseString = String(data: responseValue, encoding: .utf8) else {
                return
            }
            Log.error("\(BluetoothManagerError.unknownCharacteristic.description)")
//            print("Error: \(BluetoothManagerError.unknownCharacteristic.description)")
//            Log.d(level: .error, msg: BluetoothManagerError.unknownCharacteristic.description)
        }
        
    }
}


enum BluetoothManagerError: Error, CustomStringConvertible {
    case missingPeripheralOrCharacteristic
    case unknownCharacteristic
    case scanTimeout
    case sendMessageTimeout
    case stringConversionFailed
    case noData
    case incorrectDataConversion
    case peripheralNotConnected
    case sendingMessagesInProgress
    case timeout
    case peripheralNotFound
    case noResponse
    case unknownError
    
    public var description: String {
        switch self {
        case .missingPeripheralOrCharacteristic:
            return "Error: Device not connected. Make sure the device is correctly connected."
        case .scanTimeout:
            return "Error: Scan timed out. Please try to scan again or check the device's Bluetooth connection."
        case .sendMessageTimeout:
            return "Error: Send message timed out. Please try to send the message again or check the device's Bluetooth connection."
        case .stringConversionFailed:
            return "Error: Failed to convert string. Please make sure the string is in the correct format."
        case .noData:
            return "Error: No Data"
        case .unknownCharacteristic:
            return "Error: Unknown characteristic"
        case .incorrectDataConversion:
            return "Error: Incorrect data conversion"
        case .peripheralNotConnected:
            return "Error: Peripheral not connected"
        case .sendingMessagesInProgress:
            return "Error: Sending messages in progress"
        case .timeout:
            return "Error: Timeout"
        case .peripheralNotFound:
            return "Error: Peripheral not found"
        case .noResponse:
            return "Error: no response from the command request"
        case .unknownError:
            return "Error: Unknown Error"
        }
    }
}

extension String: LocalizedError {
    public var errorDescription: String? { return self }
}
