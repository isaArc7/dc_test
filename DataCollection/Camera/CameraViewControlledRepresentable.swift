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
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        
        return view
    }
    
    public func updateUIView(_ uiView: VideoPreviewView, context: Context) { }
    
    class VideoPreviewView: UIView {

       override class var layerClass: AnyClass {
          AVCaptureVideoPreviewLayer.self
       }
    
       var videoPreviewLayer: AVCaptureVideoPreviewLayer {
          return layer as! AVCaptureVideoPreviewLayer
       }
    }
}
