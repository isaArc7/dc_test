//
//  HistoryView.swift
//  DataCollection
//
//  Created by 汤笑寒 on 2024-09-24.
//

import SwiftUI

class HistoryViewModel: ObservableObject {
    @Published var pubCollections: [String] = []
    var selectedURL: URL? = nil
    
    public static var shared: HistoryViewModel = {
        let mgr = HistoryViewModel()
        return mgr
    }()
}

struct HistoryView: View {
    @ObservedObject var viewModel = HistoryViewModel.shared
    @ObservedObject var samplingMgr = SamplingManager.shared
    @State private var showShareSheet = false
    
    var body: some View {
        VStack {
            BackButtonView()
            
            Text("History")
                .font(.title)
                .multilineTextAlignment(.center)
            
            Divider()
            
            CollectionListRepresentable(urls: samplingMgr.pubCollections)
                .ignoresSafeArea()
            
            Spacer()
        }
    }
}

#Preview {
    HistoryView()
}
