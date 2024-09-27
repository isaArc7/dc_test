//
//  ContentView.swift
//  MLDataCollectionApp
//
//  Created by 汤笑寒 on 2024-07-22.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var tabViewModel = TabBarViewModel.shared
    @ObservedObject var featureViewModel = FeatureViewModel.shared
    
    var body: some View {
        VStack {
            VStack() {
                if tabViewModel.pubCurrentPage == .feature {
                    FeatureView()
                }
                
                if tabViewModel.pubCurrentPage == .param {
                    ParamsView()
                }
            }
            
            VStack() {
                if !(featureViewModel.page == .home) {}
                else {
                    TabBarView()
                        .frame(height: 50)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
