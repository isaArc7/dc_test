//
//  TabBarView.swift
//  MLDataCollectionApp
//
//  Created by 汤笑寒 on 2024-07-22.
//

import SwiftUI

enum TabBarPage: String {
    case feature = "Feature"
    case param = "Car Parameters"
}

class TabBarViewModel: ObservableObject {
    @Published var pubCurrentPage: TabBarPage = .feature
    
    public static var shared: TabBarViewModel = {
        let mgr = TabBarViewModel()
        return mgr
    }()
}

struct TabBarView: View {
    @ObservedObject var viewModel = TabBarViewModel.shared
    
    var body: some View {
        HStack() {
            Button {
                viewModel.pubCurrentPage = .feature
            } label: {
                Text("Home")
            }
            
            Divider()
            .frame(height: 50)
            
            Button {
                viewModel.pubCurrentPage = .param
            } label: {
                Text("Manage Parameters")
            }
        }
    }
}

#Preview {
    TabBarView()
}
