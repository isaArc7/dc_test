//
//  HomeView.swift
//  DataCollection
//
//  Created by 汤笑寒 on 2024-09-25.
//

import SwiftUI

struct HomeView: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizaontalSizeClass
    
    var isLandscape: Bool {
        verticalSizeClass == .compact
    }
    
    var body: some View {
        VStack() {
            HStack() {
                Spacer()
                bluetoothViewButton
                    .font(.system(size: 20))
                    .fontWeight(.medium)
                    .padding()
            }
            
            VStack() {
                
                if isLandscape {
                    HStack {
                        dataSourceViewButton
                        cameraViewButton
                        historyViewButton
                    }
                    .padding(.top, 80)
                } else {
                    VStack {
                        dataSourceViewButton
                        cameraViewButton
                        historyViewButton
                    }
                    .padding(.top, 40)
                }
            }
        }

        Spacer()
    }
    
    private var bluetoothViewButton: some View {
        Button {
            FeatureViewModel.shared.page = .managedevice
        } label: {
            Text("Bluetooth")
        }
    }
    
    private var dataSourceViewButton: some View {
        Button {
            FeatureViewModel.shared.page = .datasource
        } label: {
            Text("Data Source")
                .frame(width: 200, height: 100)
        }
        .buttonStyle(.bordered)
        .padding()

    }
    
    private var cameraViewButton: some View {
        Button {
            FeatureViewModel.shared.page = .camera
        } label: {
            Text("Camera")
                .frame(width: 200, height: 100)
        }
        .buttonStyle(.bordered)
        .padding()

    }
    
    private var historyViewButton: some View {
        Button {
            FeatureViewModel.shared.page = .history
        } label: {
            Text("History")
                .frame(width: 200, height: 100)
        }
        .buttonStyle(.bordered)
        .padding()
        
    }
}

#Preview {
    HomeView()
}
