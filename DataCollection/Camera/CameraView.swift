//
//  CameraView.swift
//  MLDataCollectionApp
//
//  Created by 汤笑寒 on 2024-07-22.
//

import SwiftUI
import AVFoundation

class CameraViewModel: ObservableObject {
    @Published var pubIsCollecting: Bool = false
    public static var shared: CameraViewModel = {
        let mgr = CameraViewModel()
        return mgr
    }()
    
    func startCollecting() {
        SamplingManager.shared.startSampling()
    }
    
    func stopCollecting() {
        SamplingManager.shared.stopSampling()
    }
    
    func processElapsedTime(elapsedTime: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad

        // Convert the elapsed time to HH:MM:SS format
        let formattedElapsedTime = formatter.string(from: elapsedTime)
        return formattedElapsedTime!
    }
}


struct CameraView: View {
    @ObservedObject var viewModel = CameraViewModel.shared
    @ObservedObject var samplingMgr = SamplingManager.shared
    
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizaontalSizeClass
    
    var isLandscape: Bool {
        verticalSizeClass == .compact
    }
    
    var body: some View {
        ZStack {
            if isLandscape {
                HStack {
                    VStack {
                        dataWindow
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        Spacer()
                        BackButtonView()
                    }
                    Spacer()
                    VStack {
                        unsureButton
                            .frame(width: 120)
                        fsnowButton
                            .frame(width: 120)
                        collectButton
                            .frame(width: 120)
                        psnowButton
                            .frame(width: 120)
                        dryButton
                            .frame(width: 120)
                    }
                }
                .padding()
                .edgesIgnoringSafeArea(.all)
            } else {
//                VStack {
//                    BackButtonView()
//                    Spacer()
//                }
                VStack {
                    BackButtonView()
                    Spacer().frame(height: 10)
                    dataWindow
                    Spacer()
                    VStack {
                        collectButton
                            .frame(height: 40)
                        HStack {
                            dryButton
                                .frame(height: 100)
                            psnowButton
                                .frame(height: 100)
                            fsnowButton
                                .frame(height: 100)
                            unsureButton
                                .frame(height: 100)
                        }
                    }
                }
                .zIndex(2)
            }
            
            VStack {
//                if isLandscape {
//                    CameraViewControllerRepresentable().edgesIgnoringSafeArea(.all)
//                } else {
//                    CameraViewControllerRepresentable()
//                        .edgesIgnoringSafeArea(.all)
//                }
                
                CameraViewControllerRepresentable().edgesIgnoringSafeArea(.all)
                    .onRotate { UIDeviceOrientation in
//                        CameraManager.shared.stopSession()
//                        CameraManager.shared.setupCamera()
                        
//                        let currentOrientation = UIDevice.current.orientation
//
//                        var ori: AVCaptureVideoOrientation
//
//                        switch currentOrientation {
//                        case .portrait:
//                            print("im portrait")
//                            ori = .portrait
//                        case .landscapeRight:
//                            print("im landscapeRight")
//                            ori = .portrait
//                        case .landscapeLeft:
//                            print("im landscapeLeft")
//                            ori = .portrait
//                        case .portraitUpsideDown:
//                            print("portraitUpsideDown")
//                            ori = .portraitUpsideDown
//                        default:
//                            ori = .portrait
//
//                        }
//                        CameraManager.shared.videoPreview?.videoPreviewLayer.connection?.videoOrientation = ori
//                        let ooo = CameraManager.shared.videoPreview?.videoPreviewLayer.connection?.videoOrientation
//                        print("1:\(UIDeviceOrientation)")
//                        print("2:\(ori)")
//                        print("3:\(ooo)")
                    }
            }
            .zIndex(1)
        }
    }
    
    private var dataWindow: some View {
        VStack(alignment: .center, spacing: 10) {
            let time = viewModel.processElapsedTime(elapsedTime: samplingMgr.pubElapsedTime)
            Text("\(time)")
                .font(.headline)
            Text("Collected \(samplingMgr.pubSamplesCollected) samples.")
                .font(.subheadline)
            
            if samplingMgr.pubPredictMode == .manual {
                Text("Label: \(samplingMgr.label)")
            }
            
            if samplingMgr.pubPredictMode == .general {
                if samplingMgr.labelProbs.count != 3 || !viewModel.pubIsCollecting {
                    Text("dry: 0\npartially covered snow: 0\nfully covered snow: 0")
                } else {
                    Text("dry: \(samplingMgr.labelProbs[0])\npartially covered snow: \(samplingMgr.labelProbs[1])\nfully covered snow: \(samplingMgr.labelProbs[2])")
                }
            }
            
            Picker("Selected Mode", selection: $samplingMgr.pubPredictMode) {
                ForEach(samplingMgr.predictModes, id: \.self) { mode in
                    Text("\(mode.rawValue)")
                }
            }
            .pickerStyle(.menu)
            .font(.subheadline)
            .padding(.horizontal)
            .background(Color.white.opacity(0.2))
            .cornerRadius(8)
            
            if !viewModel.pubIsCollecting {
                Picker("Sampling Interval", selection: $samplingMgr.pubSamplingInterval) {
                    ForEach(samplingMgr.intervals, id: \.self) { interval in
                        Text("Interval: \(interval)")
                    }
                }
                .pickerStyle(.menu)
                .font(.subheadline)
                .padding(.horizontal)
                .background(Color.white.opacity(0.2))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(viewModel.pubIsCollecting ? .red : .blue)
        .foregroundStyle(.white)
        .cornerRadius(12)
        .shadow(radius: 5)
    }
    
    private var collectButton: some View {
        Button {
            if !viewModel.pubIsCollecting {
                viewModel.startCollecting()
            } else {
                viewModel.stopCollecting()
            }
            viewModel.pubIsCollecting.toggle()
        } label: {
            ZStack {
                Rectangle()
                    .fill(viewModel.pubIsCollecting ? .red : .blue)
                    .shadow(radius: 3)
                Text(viewModel.pubIsCollecting ? "Stop Collecting" : "Start Collecting")
                    .foregroundColor(.white)
                    .fontWeight(.bold)
            }
        }
    }
    
    private var dryButton: some View {
        Button {
            samplingMgr.label = "dry"
        } label: {
            ZStack {
                Rectangle()
                    .fill(.orange)
                    .shadow(radius: 3)
                Text("dry")
                    .foregroundColor(.white)
                    .fontWeight(.bold)
            }
        }
    }
    
    private var psnowButton: some View {
        Button {
            samplingMgr.label = "partially covered snow"
        } label: {
            ZStack {
                Rectangle()
                    .fill(.orange)
                    .shadow(radius: 3)
                Text("partially covered snow")
                    .foregroundColor(.white)
                    .fontWeight(.bold)
            }
        }
    }
    
    private var fsnowButton: some View {
        Button {
            samplingMgr.label = "fully covered snow"
        } label: {
            ZStack {
                Rectangle()
                    .fill(.orange)
                    .shadow(radius: 3)
                Text("fully covered snow")
                    .foregroundColor(.white)
                    .fontWeight(.bold)
            }
        }
    }
    
    private var unsureButton: some View {
        Button {
            samplingMgr.label = "none"
        } label: {
            ZStack {
                Rectangle()
                    .fill(.orange)
                    .shadow(radius: 3)
                Text("unsure")
                    .foregroundColor(.white)
                    .fontWeight(.bold)
            }
        }
    }
}

#Preview {
    CameraView()
}


