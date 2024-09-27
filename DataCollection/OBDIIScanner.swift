//
//  OBDIIScanner.swift
//  MLDataCollectionApp
//
//  Created by Lai Wei on 2024-05-17.
//

import Foundation
import CoreBluetooth

/// `OBDIIScanner` is designed to manage OBD-II scanner operations.
/// This class encapsulates functionalities related to Bluetooth OBD-II communications,
/// including scanning, connecting, disconnecting, and sending commands to an OBD-II device.
public class OBDIIScanner: NSObject {
    /// Manages lower-level Bluetooth operations.
    var bluetoothManager: BluetoothManager
    
    /// A closure that is called when a peripheral is discovered.
    private var onPeripheralDiscovered: ((CBPeripheral) -> Void)?
    
    /// A closure that is called upon completion of a connection attempt.
    private var connectionCompletion: ((Bool, Error?)-> Void)?
    
    /// A closure that is called upon completion of a disconnection attempt.
    private var disconnectionCompletion: ((Bool, Error?)-> Void)?
    
    /// Provides a singleton instance of `OBDIIScanner` for global access throughout the application.
    public static var shared: OBDIIScanner = {
        let mgr = OBDIIScanner()
        return mgr
    }()
    
    override init() {
        self.bluetoothManager = BluetoothManager()
        super.init()
        self.bluetoothManager.delegate = self
    }
     
    /// Starts scanning for Bluetooth peripherals. Discovered peripherals are handled by the provided closure.
    ///
    /// You can add this function into your own scanning to handle the bluetooth scan:
    ///
    /// ```swift
    ///func startScanning() {
    ///    OBDIIScanner.shared.startScanning { peripheral in
    ///        // Your action for the discovered peripheral
    ///    }
    ///}
    /// ```
    /// - Parameter handler: A closure that is called for each discovered peripheral.
    public func startScanning(handler: @escaping (CBPeripheral) -> Void){
        self.onPeripheralDiscovered = handler
        bluetoothManager.startScanning()
    }
    
    /// Attempts to connect to a specific Bluetooth peripheral.
    ///
    /// You can add this function into your own connect function to handle the bluetooth connection:
    ///
    /// ```swift
    ///func connect(_ device: CBPeripheral) {
    ///    OBDIIScanner.shared.connect(to: device) { success, error in
    ///        if success {
    ///            // Your action for the successful connection
    ///           print("successfully connect to device")
    ///       } else {
    ///            // Your action for the failed connection
    ///            print("Failed to connect to device")
    ///        }
    ///    }
    ///}
    /// ```
    /// - Parameters:
    ///   - peripheral: The peripheral to connect to.
    ///   - completion: A closure called when the connection attempt completes, indicating success or failure.
    public func connect(to peripheral: CBPeripheral, completion: @escaping (Bool, Error?)-> Void) {
        self.connectionCompletion = completion
        bluetoothManager.connect(to: peripheral)
    }
    
    /// Disconnects from a connected Bluetooth peripheral.
    ///
    /// You can add this function into your own disconnect function to handle the bluetooth disconnection:
    ///
    /// ```swift
    ///func disconnect(_ device: CBPeripheral) {
    ///    OBDIIScanner.shared.disconnect(from: device) { success, error in
    ///        if success {
    ///            // Your action for the successful connection
    ///           print("successfully connect to device")
    ///       } else {
    ///            // Your action for the failed connection
    ///            print("Failed to connect to device")
    ///        }
    ///    }
    ///}
    /// ```
    /// - Parameters:
    ///   - peripheral: The peripheral to disconnect from.
    ///   - completion: A closure called when the disconnection attempt completes, indicating success or failure.
    public func disconnect(from peripheral: CBPeripheral,completion: @escaping (Bool, Error?)-> Void)  {
        self.disconnectionCompletion = completion
        bluetoothManager.disconnect(from: peripheral)
    }
    
    /// Sends a command to the connected OBD-II device.
    ///
    /// You can use this function to send commands to the OBDII device:
    ///
    /// ```swift
    ///func getAvailablePIDs() {
    ///   OBDIIScanner.shared.sendCommand("0100",timeout: 20) { result in
    ///        switch result {
    ///        case .success(let response):
    ///            // Your action for the successful response
    ///            print("available PIDs are \(response)")
    ///       case .failure(let error):
    ///            // Your action for the failure
    ///            print("failed to get PIDs, error:  \(error)")
    ///    }
    ///}
    /// ```
    /// - Parameters:
    ///   - command: The command string to send.
    ///   - timeout: The maximum duration in seconds to wait for a response.
    ///   - completion: A closure that processes the result of the command as success or failure.
    public func sendCommand(_ command: OBDIICommand, timeout: TimeInterval,completion: @escaping (Result<[String], Error>) -> Void) {
        bluetoothManager.sendCommand(command.rawValue, timeout: timeout, completion: completion)
    }
    
    /// Sets up the vehicle communication by sending initialization commands to the OBD-II device.
    ///
    /// You can set up vehicle immediately when the device connection is successful:
    ///
    /// ```swift
    ///func connect(_ device: CBPeripheral) {
    ///    OBDIIScanner.shared.connect(to: device) { success, error in
    ///        if success {
    ///           OBDIIScanner.shared.setupVehicle { success, responses, error in
    ///               if success {
    ///                   // your action for the successful vehicle setup responses
    ///                   print("the protocol is \(String(describing: responses))")
    ///               } else if let error =  error {
    ///                    // your action for the failed vehicle setup
    ///                   print(error)
    ///                } else {
    ///                    // your action for the failed vehicle setup
    ///                    print("Failed to connect to vehicle")
    ///                }
    ///            }
    ///           print("successfully connect to device")
    ///        } else {
    ///            print("Failed to connect to device")
    ///        }
    ///    }
    ///}
    /// ```
    /// - Parameters:
    ///   - timeout: The maximum duration in seconds to wait for each command's response.
    ///   - completion: A closure called with the result of the setup process, indicating success or failure and providing relevant messages.
    public func setupVehicle(timeout: TimeInterval = 10.0, completion: @escaping (Bool, [String]?, String?) -> Void) {
        sendCommand(OBDIICommand.reset,timeout: timeout) {[weak self] result in // 1. Reset the device
            switch result {
            case .success(let responses):
                Log.info("Response from resetting: \(responses)")
                self?.sendCommand(OBDIICommand.disableEcho,timeout: timeout){[weak self] result in //2. Disable echo response
                    switch result {
                    case .success:
                        self?.sendCommand(OBDIICommand.autoSelectProtocol,timeout: timeout){ result in  // 3. Automatically select the protocol.
                            switch result {
                            case .success(let responses):
                                if responses.contains("OK") {
                                    self?.sendCommand(OBDIICommand.headOn, timeout: timeout) { result in
                                        switch result {
                                        case.success(let responses):
                                            if responses.contains("OK") {
                                                completion(true, responses, "Protocol set to automatic. Heads are turned on. Ready to communicate")
                                            } else {
                                                completion(false, responses, "Failed to turn heads on: \(responses)")
                                            }
                                        case .failure(let error):
                                            completion(false,nil, "Failed to turn heads on: \(error)")
                                        }
                                    }
                                } else {
                                    completion(false, responses, "Failed to set protocol to automatic: \(responses)")
                                }
                            case .failure(let error):
                                completion(false, nil, "Failed to set protocol to automatic: \(error)")
                            }
                        }
                    case .failure(let error):
                        completion(false,nil, "Failed to disable echo response: \(error)")
                    }
                }
                
            case .failure(let error):
//                print("Failed to reset the device, error: \(error)")
                completion(false, nil, "Failed to reset the device, error: \(error)")
            }
        }
    }
}

/// Extension of OBDIIScanner to conform to BluetoothManagerDelegate.
/// Handles all updates for Bluetooth status changes and interactions with peripherals.
extension OBDIIScanner: BluetoothManagerDelegate {
    
    /// Called when a peripheral is discovered during the scanning process.
    /// Passes the discovered peripheral to the provided handler.
    /// - Parameter peripheral: The discovered Bluetooth peripheral.
    func didDiscoverPeripheral(_ peripheral: CBPeripheral) {
        onPeripheralDiscovered?(peripheral)
    }
    
    /// Called when a connection is successfully established with a peripheral.
    /// Executes the connection completion handler with a successful result.
    /// - Parameter peripheral: The peripheral that was successfully connected.
    func didConnectPeripheral(_ peripheral: CBPeripheral) {
        connectionCompletion?(true,nil)
        connectionCompletion = nil
    }
    
    /// Called when an attempt to connect to a peripheral fails.
    /// Executes the connection completion handler with an error.
    /// - Parameters:
    ///   - peripheral: The peripheral that failed to connect.
    ///   - error: The error that occurred during the connection attempt.
    func didFailToConnectPeripheral(_ peripheral: CBPeripheral, error: Error?) {
        connectionCompletion?(false,error)
        connectionCompletion = nil
    }
    
    /// Called when a connected peripheral disconnects.
    /// Executes the disconnection completion handler indicating whether the disconnection was clean.
    /// - Parameters:
    ///   - peripheral: The peripheral that disconnected.
    ///   - error: The error, if any, that led to the disconnection (nil if disconnection was intentional or without issues).
    func didDisconnectPeripheral(_ peripheral: CBPeripheral, error: Error?) {
        disconnectionCompletion?(error == nil,error)
        connectionCompletion = nil
    }
    
    /// Notifies about changes in Bluetooth connection status.
    /// This method can be used to trigger UI updates or log status changes.
    /// - Parameter status: The new connection status.
    func bluetoothStatusChanged(status: ConnectionStatus) {
        // handle the different status
    }
}




