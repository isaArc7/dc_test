//
//  CameraViewController.swift
//  MLDataCollectionApp
//
//  Created by 汤笑寒 on 2024-08-06.
//

import UIKit
import AVFoundation

class VideoPreviewView: UIView {
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    /// Convenience wrapper to get layer as its statically known type.
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
}

class CameraViewController: UIViewController {
    private var previewView = VideoPreviewView()

    override func viewDidLoad() {
        super.viewDidLoad()

        previewView.videoPreviewLayer.session = CameraManager.shared.session
//        previewView.videoPreviewLayer.videoGravity = .resizeAspectFill
        previewView.videoPreviewLayer.frame = view.bounds
//        print("in viewDidLoad: ", view.layer.bounds)
        view.layer.addSublayer(previewView.videoPreviewLayer)
       //
       //        var ori: AVCaptureVideoOrientation
       //
       //        switch currentOrientation {
       //        case .portrait:
       //            ori = .portrait
       ////            previewView.videoPreviewLayer.frame = view.layer.bounds
       //        case .landscapeRight:
       //            ori = .landscapeLeft
       ////            previewView.videoPreviewLayer.frame = view.layer.bounds
       //        case .landscapeLeft:
       //            ori = .landscapeRight
       ////            previewView.videoPreviewLayer.frame = view.layer.bounds
       //        case .portraitUpsideDown:
       //            ori = .portraitUpsideDown
       //        default:
       //            ori = .portrait
       //        }
       //        previewView.videoPreviewLayer.connection?.videoOrientation = ori
        
//        NotificationCenter.default.addObserver(self,
//                                                       selector: #selector(updatePreviewLayerOrientation),
//                                                       name: UIDevice.orientationDidChangeNotification,
//                                                       object: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewView.videoPreviewLayer.frame = view.bounds
////        print("in viewDidLayoutSubviews, .frame: ", previewView.videoPreviewLayer.frame)
////        print("in viewDidLayoutSubviews, .bounds: ",view.layer.bounds)
//        let currentOrientation = UIDevice.current.orientation
//
//        var ori: AVCaptureVideoOrientation
//
//        switch currentOrientation {
//        case .portrait:
//            ori = .portrait
////            previewView.videoPreviewLayer.frame = view.layer.bounds
//        case .landscapeRight:
//            ori = .landscapeLeft
////            previewView.videoPreviewLayer.frame = view.layer.bounds
//        case .landscapeLeft:
//            ori = .landscapeRight
////            previewView.videoPreviewLayer.frame = view.layer.bounds
//        case .portraitUpsideDown:
//            ori = .portraitUpsideDown
//        default:
//            ori = .portrait
//        }
//        previewView.videoPreviewLayer.connection?.videoOrientation = ori
    }
    
//    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
//        super.viewWillTransition(to: size, with: coordinator)
//        print("in viewDidLayoutSubviews, .frame: ", previewView.videoPreviewLayer.frame)
//        print("in viewDidLayoutSubviews, .bounds: ",view.layer.bounds)
//        
//        coordinator.animate(alongsideTransition: { _ in
//            // Code to update your layout based on the new size
//            self.updatePreviewLayerOrientation()
//        })
//    }
    
//    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
//        super.viewWillTransition(to: size, with: coordinator)
//
//        let cameraPreviewTransform = self.cameraView.transform
//
//        coordinator.animate { (context) in
//
//            let deltaTransform = coordinator.targetTransform
//            let deltaAngle: CGFloat = atan2(deltaTransform.b, deltaTransform.a)
//
//            var currentRotation = atan2(cameraPreviewTransform.b, cameraPreviewTransform.a)
//
//            // Adding a small value to the rotation angle forces the animation to occur in a the desired direction, preventing an issue where the view would appear to rotate 2PI radians during a rotation from LandscapeRight -> LandscapeLeft.
//            currentRotation += -1 * deltaAngle + 0.0001;
//            self.cameraView.layer.setValue(currentRotation, forKeyPath: "transform.rotation.z")
//            self.cameraView.layer.frame = self.view.bounds
//        } completion: { (context) in
//            let currentTransform : CGAffineTransform = self.cameraView.transform
//            self.cameraView.transform = currentTransform
//        }
//    }
    
    
    func updatePreviewLayerOrientation() {
            guard let connection = previewView.videoPreviewLayer.connection else { return }
            
            switch UIDevice.current.orientation {
            case .portrait:
                connection.videoOrientation = .portrait
            case .landscapeRight:
                connection.videoOrientation = .landscapeLeft
            case .landscapeLeft:
                connection.videoOrientation = .landscapeRight
            case .portraitUpsideDown:
                connection.videoOrientation = .portraitUpsideDown
            default:
                connection.videoOrientation = .portrait
            }
            
            previewView.videoPreviewLayer.frame = view.bounds
        }
}

