//
//  CameraManager.swift
//  MLDataCollectionApp
//
//  Created by 汤笑寒 on 2024-08-06.
//

import Foundation

import AVFoundation
import UIKit

enum ConfigStatus {
    case configured
    case unconfigured
    case unauthorized
    case failed
}

class CameraManager: NSObject, AVCaptureFileOutputRecordingDelegate, ObservableObject, AVCapturePhotoCaptureDelegate {
    var session = AVCaptureSession()
    var photoOutput = AVCapturePhotoOutput()
//    let videoOutput = AVCaptureVideoDataOutput()
    var movieOutput = AVCaptureMovieFileOutput()
    var preview : AVCaptureVideoPreviewLayer!
    let fm = FileManager.default
    
    private let sessionQueue = DispatchQueue(label: "com.DC.session")
    private let videoQueue = DispatchQueue(label: "com.DC.video")
    private let captureQueue = DispatchQueue(label: "com.DC.captureQueue")
    
    var videoPreview : CameraViewControllerRepresentable.VideoPreviewView?
    
    public static var shared: CameraManager = {
        let mgr = CameraManager()
        return mgr
    }()
    
    override init() {
        super.init()
        checkCameraPermission()
    }
    
    func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            Log.info("Camera permission is granted")
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if !granted {
                    Log.warning("Camera usage has been disabled, please enable it")
                }
            }
        case .denied:
            Log.warning("Camera usage has been disabled, please enable it") //later gets AlertManager
        case .restricted:
            Log.warning("Camera usage has been disabled, please enable it")
        @unknown default:
            Log.error("Unknown error due when granting permission for camera")
        }
    }
    
    
    /// Set up session, input, output, ...
    func setupCamera() {
        session = AVCaptureSession()
        photoOutput = AVCapturePhotoOutput()
        movieOutput = AVCaptureMovieFileOutput()
        
        session.beginConfiguration()
        
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            Log.error("Unable to access back camera.")
            return
        }
        
        //input
        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            if session.canAddInput(input) {
                session.addInput(input)
            } else {
                Log.error("Could not add camera input.")
                return
            }
            // photo output
            if session.canAddOutput(photoOutput) {
                session.sessionPreset = .high
                session.addOutput(photoOutput)
            } else {
                Log.error("Could not add photo output.")
                return
            }
            // video output
//            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_32BGRA)]
//            videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
//            if session.canAddOutput(movieOutput) {
//                session.addOutput(movieOutput)
//            } else {
//                Log.error("Could not add video output.")
//                return
//            }
            
            
            
            
//            let orientation = UIDevice.current.orientation
//            let connection = movieOutput.connection(with: .video)
//            var rotationAngle: CGFloat
//            var videoOrientation: AVCaptureVideoOrientation
//            switch orientation {
//            case .portrait:
//                rotationAngle = 0
//                videoOrientation = .portrait
//            case .landscapeLeft:
//                rotationAngle = 90
//                videoOrientation = .landscapeRight
//            case .landscapeRight:
//                rotationAngle = -90
//                videoOrientation = .landscapeLeft
//            case .portraitUpsideDown:
//                rotationAngle = 180
//                videoOrientation = .portraitUpsideDown
//            default:
//                rotationAngle = 0
//                videoOrientation = .portrait
//            }
//            if #available(iOS 17.0, *) {
//                if connection?.isVideoRotationAngleSupported(rotationAngle) ?? false {
//                    connection?.videoRotationAngle = rotationAngle
//                }
//            } else {
//                // Fallback on earlier versions
//                if connection?.isVideoOrientationSupported ?? false {
//                    connection?.videoOrientation = videoOrientation
//                }
//            }
            
            // movie output
            if session.canAddOutput(movieOutput) {
                session.addOutput(movieOutput)
            } else {
                Log.error("Could not add movie output.")
                return
            }
            
        } catch let error {
            Log.error("Unable to initialize back camera: \(error.localizedDescription)")
        }
        
        self.startSession()
        session.commitConfiguration()
    }
    
    
    /// start running the session
    func startSession() {
        DispatchQueue.global(qos: .background).async {
            self.session.startRunning()
        }
    }
    
    /// stop running the session
    func stopSession() {
        session.stopRunning()
    }
    
    func capturePhoto() {
        // photoSettings may not be reused
        let photoSettings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation() else { return }
        AllDataProvider.shared.image = UIImage(data: imageData)
        
        let datef = SamplingManager.shared.dateFormatter
        datef.dateFormat = "yyyy-MM-dd HH-mm-ss"
        
        let documentsDirectory = getDocumentsDirectory()
        let dirName = datef.string(from: SamplingManager.shared.startTime!)
        let dirURL = documentsDirectory.appendingPathComponent(dirName)
        
        //不要头铁，有些时候加上容易找bug
//        if !fm.fileExists(atPath: dirURL.path) {
//            do {
//                try FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true, attributes: nil)
//                print("Directory created at: \(dirURL.path)")
//            } catch {
//                print("Error creating directory: \(error)")
//                return
//            }
//        }
        
        let datefphoto = SamplingManager.shared.dateFormatter
        datefphoto.dateFormat = "yyyy-MM-dd HH-mm-ss.SSS"
        let photoName = datefphoto.string(from: SamplingManager.shared.samplingTime!) + ".jpg"
        let photoURL = dirURL.appendingPathComponent(photoName)
        
        do {
            try imageData.write(to: photoURL)
            print("Photo saved to: \(photoURL)")
        } catch {
            print("Error saving photo: \(error)")
        }
    }
    
    /// start recording a movie to url
    func startRecording(movieName: String) {
        let outputURL = getDocumentsDirectory().appendingPathComponent("\(movieName).mov")
        movieOutput.startRecording(to: outputURL, recordingDelegate: self)
    }
    
    func stopRecording() {
        movieOutput.stopRecording()
    }

    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Failed to record video: \(error.localizedDescription)")
        } else {
            print("Video recording successful: \(outputFileURL)")

            let datef = SamplingManager.shared.dateFormatter
            datef.dateFormat = "yyyy-MM-dd HH-mm-ss"
            
            let documentsDirectory = getDocumentsDirectory()
            let dirName = datef.string(from: SamplingManager.shared.startTime!)
            let dirURL = documentsDirectory.appendingPathComponent(dirName)
            
            let videoName = datef.string(from: SamplingManager.shared.startTime!) + ".mov"
            let videoURL = dirURL.appendingPathComponent(videoName)
            
            do {
                try fm.moveItem(at: outputFileURL, to: videoURL)
                print("Video saved to: \(videoURL)")
            } catch {
                print("Error saving video: \(error)")
            }
        }
    }
    
    func createDir(dirName: String) {
        let documentsDirectory = getDocumentsDirectory()
        let dirURL = documentsDirectory.appendingPathComponent(dirName)
        
        if !fm.fileExists(atPath: dirURL.path) {
            do {
                try fm.createDirectory(at: dirURL, withIntermediateDirectories: true)
            } catch {
                Log.error("Failed to create dir \(dirURL.path). Error: \(error)")
            }
        }
        
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}
