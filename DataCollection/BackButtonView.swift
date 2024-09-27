//
//  BackButtonView.swift
//  DataCollection
//
//  Created by 汤笑寒 on 2024-09-25.
//

import SwiftUI

struct BackButtonView: View {
    var body: some View {
        HStack {
            Button {
                FeatureViewModel.shared.page = .home
            } label: {
                Text("Back")
            }
            .padding()
            Spacer()
        }
    }
}

#Preview {
    BackButtonView()
}
