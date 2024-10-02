//
//  DataSourceView.swift
//  DataCollection
//
//  Created by 汤笑寒 on 2024-10-01.
//

import SwiftUI

class DataSourceViewModel: ObservableObject {
    @Published var pubOBDIIExpanded = false
    @Published var pubRWISExpanded = false
    @Published var pubSensorExpanded = false
    
    public static var shared: DataSourceViewModel = {
        let mgr = DataSourceViewModel()
        return mgr
    }()
    
    func onAppearFunc() {
        if AllDataProvider.shared.pubAllAvailableParams.isEmpty {
            AllDataProvider.shared.getAllAvailableParams()
        }
    }
}

struct DataSourceView: View {
    @ObservedObject var viewModel = DataSourceViewModel.shared
    @ObservedObject var dataSystem = AllDataProvider.shared
    
    var body: some View {
        VStack {
            BackButtonView()
            
            DisclosureGroup("OBDII/CAN bus Parameters", isExpanded: $viewModel.pubOBDIIExpanded) {
                ForEach(dataSystem.OBDIICommandList, id: \.self) { command in
                    HStack {
                        Spacer().frame(width: 30)
                        let isSet = dataSystem.pubAllMonitoringParams.contains(.command(command))
                        ParamRow(param: .command(command), isSet: isSet)
                    }
                }
            }
            .padding()
            .border(Color.blue)
            .cornerRadius(3.0)
            DisclosureGroup("RWIS Data", isExpanded: $viewModel.pubRWISExpanded) {
                ForEach(dataSystem.RWISParamList, id: \.self) { param in
                    HStack {
                        Spacer().frame(width: 30)
                        let isSet = dataSystem.pubAllMonitoringParams.contains(.sensor(param))
                        ParamRow(param: .sensor(param), isSet: isSet)
                    }
                }
            }
            .padding()
            .border(Color.blue)
            .cornerRadius(3.0)
            DisclosureGroup("Phone Sensors", isExpanded: $viewModel.pubSensorExpanded) {
                ForEach(dataSystem.RegularParamList, id: \.self) { param in
                    HStack {
                        Spacer().frame(width: 30)
                        let isSet = dataSystem.pubAllMonitoringParams.contains(.sensor(param))
                        ParamRow(param: .sensor(param), isSet: isSet)
                    }
                }
            }
            .padding()
            .border(Color.blue)
            .cornerRadius(3.0)
            Spacer()
        }
        .onAppear() {
            viewModel.onAppearFunc()
        }
    }
}

#Preview {
    DataSourceView()
}
