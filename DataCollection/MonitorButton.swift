//
//  MonitorButton.swift
//  MLDataCollectionApp
//
//  Created by 汤笑寒 on 2024-08-03.
//

import SwiftUI

struct MonitorButton: View {
    @State var isSet: Bool
    
    var body: some View {
        Button {
            if !isSet {}
        } label: {
            Label("Toggle Monitoring", systemImage: isSet ? "star.fill" : "star")
                .labelStyle(.iconOnly)
                .foregroundStyle(isSet ? .yellow : .gray)
        }
    }
}

#Preview {
    MonitorButton(isSet: true)
}
