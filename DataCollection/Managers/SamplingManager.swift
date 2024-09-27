//
//  SamplingManager.swift
//  MLDataCollectionApp
//
//  Created by 汤笑寒 on 2024-08-07.
//

import Foundation
import SwiftUI

class SamplingManager: ObservableObject {
    var dateFormatter = DateFormatter()
    var timer: Timer?
    var samplingTimer: Timer?
    var startTime: Date?
    @Published var pubElapsedTime: TimeInterval = 0
    var samplingTime: Date?
    @Published var pubSamplesCollected: Int = 0
    @Published var pubSamplingInterval = 0.5
    let intervals: [Double] = [0.1, 0.2, 0.5, 1, 2]
    var rowContent = ""
    @Published var label = "none"
    @Published var labelProbs : [Float] = []
    @Published var pubCollections = [URL]()
    @Published var pubPredictMode : PredictMode = .manual
    var predictModes : [PredictMode] = [.manual, .general]
    
    var fileHandle: FileHandle? = nil
    
    public static var shared: SamplingManager = {
        let mgr = SamplingManager()
        return mgr
    }()
    
    /// Default: when start sampling, it starts recording a video and request OBDII data every 0.5 second.
    /// If takePicture is true, it also takes picture every 0.5 second.
    func startSampling() {
        pubSamplesCollected = 0
        pubElapsedTime = 0
        
        startTime = Date()
        /// the file system doesn't like ':'. It changes ':' to '/'.
        dateFormatter.dateFormat = "yyyy-MM-dd HH-mm-ss"
        
        let name = dateFormatter.string(from: startTime!)
        /// 0. create dir
        CameraManager.shared.createDir(dirName: name)
        /// 1. open csv
        self.generateCSV(startTime: name)
        /// 2.. start recording the movie
        CameraManager.shared.startRecording(movieName: name)
        
        /// This function takes picture, request data, increment sample amount and record data into csv.
        if ManageDeviceViewModel.shared.pubIsConnected {
            OBDIIDataManager.shared.getResponses() {
            }
        }
        
        RegularDataManager.shared.startAllSensors()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [self] _ in
            pubElapsedTime = Date().timeIntervalSince(startTime!)
        }
        
        samplingTimer = Timer.scheduledTimer(withTimeInterval: pubSamplingInterval, repeats: true, block: { [self] _ in
            
            CameraManager.shared.capturePhoto()
            
            SamplingManager.shared.samplingTime = Date()
            dateFormatter.dateFormat = "yyyy-MM-dd HH-mm-ss.SSS"
            let timeString = dateFormatter.string(from: SamplingManager.shared.samplingTime!)
            
            var param: Param
            var paramVal: Double
            
            self.rowContent = "\(timeString),"
            
            var metadata: [Float] = []
            
            for i in 0..<AllDataProvider.shared.pubAllMonitoringParams.count {
                param = AllDataProvider.shared.pubAllMonitoringParams[i]
                paramVal = AllDataProvider.shared.allParamValues[param] ?? -1
                rowContent += "\(paramVal)" // GPS-speed's -1 is determined by the sensor, not by this -1
                
                metadata.append(Float(paramVal))
                
                if i < AllDataProvider.shared.pubAllMonitoringParams.count - 1 {
                    rowContent += ","
                } else {
                    
                    let datef = SamplingManager.shared.dateFormatter
                    datef.dateFormat = "yyyy-MM-dd HH-mm-ss"
                    let dirName = datef.string(from: SamplingManager.shared.startTime!)
                    
                    let datefphoto = SamplingManager.shared.dateFormatter
                    datefphoto.dateFormat = "yyyy-MM-dd HH-mm-ss.SSS"
                    let photoName = datefphoto.string(from: SamplingManager.shared.samplingTime!) + ".jpg"
                    
                    let photoPath = "\(dirName)/\(photoName)"
                    
                    if pubPredictMode == .general {
                        if let image = AllDataProvider.shared.image {
                            labelProbs = ClassificationManager.shared.runModel(image: image, metadata: metadata)
                            label = ClassificationManager.shared.labelList[labelProbs.firstIndex(of: labelProbs.max() ?? 0) ?? 0]
                        }
                    }
                    
                    rowContent += ",\(photoPath),\(label)\n"
                    self.pubSamplesCollected += 1
                }
                
            }
            
            writeNewRow(rowContent) {
            }
        })
    }
    
    func stopSampling() {
        timer?.invalidate()
        samplingTimer?.invalidate()
        self.closeStream()
        CameraManager.shared.stopRecording()
        RegularDataManager.shared.stopAllSensors()
    }
    
    func writeNewRow(_ row: String, completion: @escaping ()->()) {
        guard let fileHandle = fileHandle else { return }
        do {
            try self.fileHandle?.seekToEnd()
            if let data = row.data(using: .utf8) {
                fileHandle.write(data)
            }
        } catch {
            Log.error("Failed to place file pointed to the end of the file. Error: \(error)")
        }
        
        completion()
    }
    
    func getDocumentsDirectory() -> URL {
            return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func generateCSV(startTime: String) {
        
        //startTime is also the name of the dir
        let documentsDirectory = getDocumentsDirectory()
        let dirURL = documentsDirectory.appendingPathComponent(startTime)
        let fileURL = dirURL.appendingPathComponent("\(startTime).csv")
        FileManager.default.createFile(atPath: fileURL.path, contents: nil)
        
        //for History record
        pubCollections.append(dirURL)

        do {
            fileHandle = try FileHandle(forWritingTo: fileURL)
            var heading = "Time,"
            for i in 0..<AllDataProvider.shared.pubAllMonitoringParams.count {
                let param = AllDataProvider.shared.pubAllMonitoringParams[i]
                if case let .command(command) = param {
                    heading += "\(command.name)"
                }
                if case let .sensor(string) = param {
                    heading += "\(string)"
                }
                if i < AllDataProvider.shared.pubAllMonitoringParams.count - 1 {
                    heading += ","
                } else {
                    heading += ",ImageName,Label\n"
                }
            }
            if let data = heading.data(using: .utf8) {
                fileHandle!.write(data)
            }
        } catch {
            Log.error("Failed to create fileHandle. Error: \(error)")
        }
    }
    
    /// This is used to end the streaming for the data
    func closeStream() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            do{
                try self.fileHandle?.close()
                self.fileHandle = nil
            } catch {
                Log.error("Failed to close fileHandle. Error: \(error)")
            }
        }
    }
}
