//
//  ManageDeviceView.swift
//  MLDataCollectionApp
//
//  Created by 汤笑寒 on 2024-07-22.
//

import SwiftUI
import CoreBluetooth


class ManageDeviceViewModel: ObservableObject {
    @Published var pubDiscoveredPeripherals: [CBPeripheral] = []
    @Published var pubConnectedPeripheral: CBPeripheral? = nil
    @Published var pubIsConnected = false
    @Published var pubIsWaiting = false
    
    public static var shared: ManageDeviceViewModel = {
        let mgr = ManageDeviceViewModel()
        return mgr
    }()
    
    func findPeripherals() {
        OBDIIScanner.shared.startScanning { peripheral in
            var discoveredPeripheralsCopy = [CBPeripheral]()
            discoveredPeripheralsCopy.append(contentsOf: self.pubDiscoveredPeripherals)
            guard let _ = peripheral.name, !discoveredPeripheralsCopy.contains(peripheral) else {return}
            discoveredPeripheralsCopy.append(peripheral)
            DispatchQueue.main.async {
                self.pubDiscoveredPeripherals = discoveredPeripheralsCopy
            }
        }
    }
    
    func connectPeripheral(to device: CBPeripheral) {
        if device == pubConnectedPeripheral {
            return
        }
        
        pubIsWaiting = true
        
        if pubConnectedPeripheral != nil {
            let device = pubConnectedPeripheral
            disconnectPeripheral(to: device!)
        }
        
        OBDIIScanner.shared.connect(to: device) { success, error in
            if success {
                Log.info("Connect to \(device.name ?? "Unknown") succesfully.")
                OBDIIScanner.shared.setupVehicle { success, responses, error in
                    if success {
                        Log.info("Succesfully set up OBD2. Responses: \(String(describing: responses)). Description: \(String(describing: error))")
                        
                        self.pubConnectedPeripheral = device
                        self.pubIsConnected = true
                        self.pubIsWaiting = false
                        
                    } else if let error = error {
                        Log.error("Error: \(error)")
                        self.pubIsWaiting = false
                    } else {
                        Log.error("Setup failed for reasons that are not captured by the error object.")
                        self.pubIsWaiting = false
                    }
                }
            } else {
                Log.error("Failed to connect \(device.name ?? "Unknown"). Error: \(String(describing: error))")
                // idk why the peripheral's state is still connected in this case...
                // that's why i add disconnectPeripheral
                self.disconnectPeripheral(to: device)
                self.pubIsWaiting = false
            }
        }
    }
    
    func disconnectPeripheral(to device: CBPeripheral) {
        OBDIIScanner.shared.disconnect(from: device) { success, error in
            if success {
                Log.info("Disconnect with \(device.name ?? "Unknown") succesfully.")
                self.pubIsConnected = false
                self.pubConnectedPeripheral = nil
            } else {
                Log.error("Failed to disconnect \(device.name ?? "Unknown").")
            }
        }
    }
}


struct ManageDeviceView: View {
    @ObservedObject var viewModel = ManageDeviceViewModel.shared
    @State private var isViewVisible: Bool = false
    
    var Status: String {
        viewModel.pubIsConnected ? "Connected to \(viewModel.pubConnectedPeripheral?.name ?? "nil")" : "Disconnected"
    }
    
    var body: some View {
        ZStack {
            VStack {
                BackButtonView()
                
                HStack {
                    Text("Discovered Devices")
                        .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                        .multilineTextAlignment(.center)
                }
                
                VStack() {
                    HStack {
                        Text("Status: \(Status)")
                        Spacer()
                    }
                    .padding()
                    Divider()
                }
                
                List(viewModel.pubDiscoveredPeripherals, id: \.identifier) { peripheral in
                    Button {
                        viewModel.connectPeripheral(to: peripheral)
                        isViewVisible = true
                    } label: {
                        PeripheralRow(peripheralWrapper: PeripheralWrapper(peripheral: peripheral))
                    }
                }
                
                Spacer()
                
                Button {
                    if viewModel.pubIsConnected {
                        let device = viewModel.pubConnectedPeripheral
                        viewModel.disconnectPeripheral(to: device!)
                    }
                } label: {
                    Text("Disconnect")
                }.foregroundStyle(viewModel.pubIsConnected ? .blue : .gray)
            }
            .onAppear() {
                viewModel.findPeripherals()
            }
            .onDisappear() {
                OBDIIScanner.shared.bluetoothManager.stopScanning()
            }
            .zIndex(1)
            
            if isViewVisible {
                Color.gray
                    .opacity(0.3)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        if !viewModel.pubIsWaiting {
                            isViewVisible = false
                        }
                    }
                    .zIndex(2)
            }
            
            if isViewVisible {
                ZStack {
                    VStack {
                        HStack {
                            if viewModel.pubIsWaiting == true {
                                Text("Trying to connect...")
                            } else {
                                if viewModel.pubIsConnected == true {
                                    Text("Connect successfully.")
                                } else {
                                    Text("Failed to connect.")
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white)
                    // the order of cornerRadius and .shadow make a difference!
                    // if i put cornerRadius below shadow, the shadow applies to the text
                    .cornerRadius(10)
                    .shadow(radius: 10)
                }
                .frame(width: 260, height: 260)
                .zIndex(2)
                .onTapGesture {
                    isViewVisible = true
                }
            }
        }
    }
}

#Preview {
    ManageDeviceView()
}
