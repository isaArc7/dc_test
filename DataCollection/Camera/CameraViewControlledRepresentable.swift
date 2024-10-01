//
//  CameraViewControlledRepresentable.swift
//  MLDataCollectionApp
//
//  Created by 汤笑寒 on 2024-08-07.
//

import SwiftUI
import AVFoundation

//struct CameraViewControllerRepresentable: UIViewControllerRepresentable {
//    func makeUIViewController(context: Context) -> CameraViewController {
//        return CameraViewController()
//    }
//
//    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
//
//    }
//}

struct CameraViewControllerRepresentable: UIViewRepresentable {
    
    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.backgroundColor = .black
        view.videoPreviewLayer.session = CameraManager.shared.session
        view.frame = view.bounds
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        CameraManager.shared.videoPreview = view
//        view.videoPreviewLayer.connection?.videoOrientation = .landscapeRight
        
        return view
    }
    
    public func updateUIView(_ uiView: VideoPreviewView, context: Context) {
        let currentOrientation = UIDevice.current.orientation
        
        var ori: AVCaptureVideoOrientation

        switch currentOrientation {
        case .portrait:
            print("im portrait")
            ori = .portrait
        case .landscapeRight:
            print("im landscapeRight")
            ori = .landscapeLeft
        case .landscapeLeft:
            print("im landscapeLeft")
            ori = .landscapeRight
        case .portraitUpsideDown:
            print("portraitUpsideDown")
            ori = .portraitUpsideDown
        default:
            ori = .portrait

        }
        CameraManager.shared.videoPreview?.videoPreviewLayer.connection?.videoOrientation = ori
    }
    
    class VideoPreviewView: UIView {

       override class var layerClass: AnyClass {
          AVCaptureVideoPreviewLayer.self
       }
    
       var videoPreviewLayer: AVCaptureVideoPreviewLayer {
          return layer as! AVCaptureVideoPreviewLayer
       }
    }
}
