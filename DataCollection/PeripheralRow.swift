//
//  PeripheralRow.swift
//  MLDataCollectionApp
//
//  Created by 汤笑寒 on 2024-07-22.
//

import SwiftUI
import CoreBluetooth

struct PeripheralRow: View {
    @ObservedObject var peripheralWrapper: PeripheralWrapper
    
    var body: some View {
        HStack {
            Text(peripheralWrapper.pubPeripheral?.name ?? "Unknown")

            Spacer()

            if peripheralWrapper.pubPeripheral?.state == .connected {
                Image(systemName: "checkmark")
            }
        }
        .padding()
    }
}
