//
//  ParamsView.swift
//  MLDataCollectionApp
//
//  Created by 汤笑寒 on 2024-07-22.
//

import SwiftUI

class ParamsViewModel: ObservableObject {
    @Published var pubShowMonitoredOnly = false
    @Published var pubDataSystem = AllDataProvider.shared
    @Published var pubSelectAll = false
    
    var filteredParams: [Param] {
        pubDataSystem.pubAllAvailableParams.filter { param in
            (!pubShowMonitoredOnly || pubDataSystem.pubAllMonitoringParams.contains(param))
        }
    }
    
    public static var shared: ParamsViewModel = {
        let mgr = ParamsViewModel()
        return mgr
    }()
    
    func onAppearFunc() {
        if pubDataSystem.pubAllAvailableParams.isEmpty {
            pubDataSystem.getAllAvailableParams()
        }
    }
    
    func toggleSelectAll(_ selectAll: Bool) {
        if selectAll {
            var copy: [Param] = []
            for param in pubDataSystem.pubAllAvailableParams {
                copy.append(param)
                if case let .command(obd2command) = param {
                    OBDIIDataManager.shared.monitoredPids.append(obd2command)
                }
            }
            self.pubDataSystem.pubAllMonitoringParams = copy
        } else {
            pubDataSystem.pubAllMonitoringParams = []
            OBDIIDataManager.shared.monitoredPids = []
        }
    }
    
}

struct ParamsView: View {
    @ObservedObject var viewModel = ParamsViewModel.shared
    @ObservedObject var dataSystem = AllDataProvider.shared
    
    var body: some View {
        ZStack {
            if dataSystem.pubAllAvailableParams.isEmpty {
                VStack {
                    Text("Checking, please wait...")
                }
                .zIndex(1)
            }
            
            
            VStack {
                HStack {
                    Text("Discovered Devices")
                        .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                        .multilineTextAlignment(.center)
                }
                
//
//                var filteredParams: [String] {
//                    dataSystem.allAvailableParams.filter { param in
//                        (!viewModel.pubShowMonitoredOnly || dataSystem.allMonitoringParams.contains(param))
//                    }
//                }
                
                List {
                    Toggle(isOn: $viewModel.pubSelectAll) {
                        Text("Select All")
                    }
                    .onChange(of: viewModel.pubSelectAll) { newValue in
                        viewModel.toggleSelectAll(newValue)
                    }
                    
                    Toggle(isOn: $viewModel.pubShowMonitoredOnly) {
                        Text("Show Monitored Params Only")
                    }
                    
                    
                    ForEach(viewModel.filteredParams, id: \.self) { param in
                        let isSet = viewModel.pubDataSystem.pubAllMonitoringParams.contains(param)
                        ParamRow(param: param, isSet: isSet)
                    }
                }
                .animation(.default, value: viewModel.filteredParams)
                
                Spacer()
            }
            .onAppear() {
                viewModel.onAppearFunc()
            }
        }
    }
}

#Preview {
    ParamsView()
}
