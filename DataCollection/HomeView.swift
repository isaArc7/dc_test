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
            VStack() {
                Text("Home")
                    .font(.title)
            }
            
            VStack() {
                if isLandscape {
                    HStack {
                        manageDeviceViewButton
                        cameraViewButton
                        historyViewButton
                    }
                    .padding(.top, 80)
                } else {
                    VStack {
                        manageDeviceViewButton
                        cameraViewButton
                        historyViewButton
                    }
                    .padding(.top, 60)
                }
            }
        }

        Spacer()
    }
    
    private var manageDeviceViewButton: some View {
        Button {
            FeatureViewModel.shared.page = .managedevice
        } label: {
            Text("Manage Devices")
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
