//
//  ParamRow.swift
//  MLDataCollectionApp
//
//  Created by 汤笑寒 on 2024-08-07.
//

import SwiftUI

struct ParamRow: View {
    var param: Param
    var isSet: Bool
    
    var body: some View {
        HStack {
                if case let .command(obd2command) = param {
                    Text("\(obd2command.name)")
                }
                if case let .sensor(sensor) = param {
                    Text("\(sensor)")
                }
                
                Spacer()
                
            if AllDataProvider.shared.pubAllAvailableParams.contains(param) {
                Button {
                    if !isSet {
                        AllDataProvider.shared.pubAllMonitoringParams.append(param)
                        // if it's a obd2command, we also need to append it to the obd2's list
                        if case let .command(obd2command) = param {
                            OBDIIDataManager.shared.monitoredPids.append(obd2command)
                        }
                    } else {
                        if let index = AllDataProvider.shared.pubAllMonitoringParams.firstIndex(of: param) {
                            AllDataProvider.shared.pubAllMonitoringParams.remove(at: index)
                        }
                        // if it's a obd2command, we also need to remove it from the obd2's list
                        if case let .command(obd2command) = param {
                            if let i = OBDIIDataManager.shared.monitoredPids.firstIndex(of: obd2command) {
                                OBDIIDataManager.shared.monitoredPids.remove(at: i)
                            }
                        }
                    }
                } label: {
                    Label("Toggle Monitoring", systemImage: isSet ? "star.fill" : "star")
                        .labelStyle(.iconOnly)
                        .foregroundStyle(isSet ? .yellow : .gray)
                }
            }
        }
    }
}

#Preview {
    ParamRow(param: .sensor("Latitude"), isSet: true)
}
