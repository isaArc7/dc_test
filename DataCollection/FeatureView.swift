//
//  FeatureView.swift
//  MLDataCollectionApp
//
//  Created by 汤笑寒 on 2024-07-22.
//

import SwiftUI

enum PageType: String {
    case home = "Home"
    case camera = "Camera"
    case history = "History"
    case managedevice = "Manage Device"
}

class FeatureViewModel: ObservableObject {
    @Published var page: PageType = .home
    
    public static var shared: FeatureViewModel = {
        let mgr = FeatureViewModel()
        return mgr
    }()
}

struct FeatureView: View {
    @ObservedObject var pageMgr = FeatureViewModel.shared
    
    var body: some View {
        VStack {
            if pageMgr.page == .home {
                HomeView()
            }
            
            if pageMgr.page == .camera {
                CameraView()
            }
            
            if pageMgr.page == .managedevice {
                ManageDeviceView()
            }
            
            if pageMgr.page == .history {
                HistoryView()
            }
        }
    }
}


#Preview {
    FeatureView()
}
