//
//  CollectionListRepresentable.swift
//  DataCollection
//
//  Created by 汤笑寒 on 2024-09-24.
//

import Foundation
import SwiftUI

struct CollectionListRepresentable: UIViewControllerRepresentable {
    typealias UIViewControllerType = CollectionList
    
    var urls: [URL]
    
    func makeUIViewController(context: Context) -> CollectionList {
        let vc = CollectionList()
        vc.urls = urls
        return vc
    }
    
    func updateUIViewController(_ uiViewController: CollectionList, context: Context) {
        uiViewController.urls = urls
        uiViewController.tableView.reloadData()
    }
}
