//
//  CollectionList.swift
//  DataCollection
//
//  Created by 汤笑寒 on 2024-09-24.
//

import Foundation
import UIKit
import SSZipArchive

class CollectionList: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let tableView = UITableView()
    var urls: [URL] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.frame = self.view.bounds
        view.addSubview(tableView)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return urls.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let url = urls[indexPath.row]
        let dirName = url.path.split(separator: "/").last ?? "No Name"
        cell.textLabel?.text = String(dirName)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        presentShareSheet(urls[indexPath.row]) {
            self.tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    private func presentShareSheet(_ dirURL: URL, completion: @escaping ()->()) {
        let dirPath = dirURL.path
        let zipPath = "\(dirPath).zip"
        let success = SSZipArchive.createZipFile(atPath: zipPath, withContentsOfDirectory: dirPath)
        if !success {
            Log.error("Failed to zip \(dirPath) at \(zipPath).")
        } else {
            Log.info("Succesffuly zip \(dirPath) at \(zipPath).")
        }
        
        let fileManager = FileManager.default
            if !fileManager.fileExists(atPath: zipPath) {
                Log.error("Zip file does not exist at path: \(zipPath)")
                return
            }
        
        let zipURL = URL(fileURLWithPath: zipPath)
        let shareSheet = UIActivityViewController(activityItems: [zipURL], applicationActivities: nil)
        self.present(shareSheet, animated: true)
        completion()
    }
}
