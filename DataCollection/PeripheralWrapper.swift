//
//  PeripheralWrapper.swift
//  MLDataCollectionApp
//
//  Created by 汤笑寒 on 2024-08-21.
//

import SwiftUI
import CoreBluetooth

class PeripheralWrapper: ObservableObject {
    @Published var pubPeripheral: CBPeripheral?
    
    init(peripheral: CBPeripheral? = nil) {
        self.pubPeripheral = peripheral
    }
}
