//
//  Classifier.swift
//  SmartRCDetector
//
//  Created by Xu Liu on 2024-02-18.
//

import Foundation
import TensorFlowLite
import SwiftUI

enum PredictMode: String {
    case general = "Auto Label"
    case manual = "Manual"
}

public class ClassificationManager: ObservableObject {
    var interpreter: Interpreter? = nil
    var labelList: [String] = ["dry", "partially covered snow", "fully covered snow"]
    
    private var batchSize: Int? = nil
    private var inputImageWidth: Int? = nil
    private var inputImageHeight: Int? = nil
    private var inputPixelSize: Int? = nil
    private var outputImageWidth: Int? = nil
    private var outputImageHeight: Int? = nil
    private var outputClassCount: Int? = nil
    
    public static var shared: ClassificationManager = {
        let mgr = ClassificationManager()
        return mgr
    }()
    
    init() {
        // Load the TensorFlow Lite model
        guard let modelPath = Bundle.main.path(forResource: "dc_test", ofType: "tflite") else {
            Log.error("Cannot find dc_test model.")
            return
        }
        do {
            self.interpreter = try Interpreter(modelPath: modelPath)
            
            try interpreter!.allocateTensors()
            
            let inputShape = try interpreter!.input(at: 0).shape
            let outputShape = try interpreter!.output(at: 0).shape
            
            // Read input shape from model.
            self.batchSize = inputShape.dimensions[0]
            self.inputImageWidth = inputShape.dimensions[1]
            self.inputImageHeight = inputShape.dimensions[2]
            self.inputPixelSize = inputShape.dimensions[3]
            
            // Read output shape from model.
            self.outputClassCount = outputShape.dimensions[1]
            print(self.outputClassCount)
            
        } catch {
            Log.error("Failed to init the interpreter.")
        }
    }

    
    func runModel(image: UIImage, metadata: [Float]) -> [Float] {
        
        guard let rgbData = image.scaledData(
                    with: CGSize(width: self.inputImageWidth!, height: self.inputImageHeight!),
                    byteCount: self.inputImageWidth! * self.inputImageHeight! * self.inputPixelSize!
                      * self.batchSize!,
                    isQuantized: false
                  )
        else {
            print("Failed to convert the image buffer to RGB data.")
            return []
        }
        
        try! interpreter!.copy(rgbData, toInputAt: 0)

        // Create a Data object from the float array
        let metadataData = metadata.withUnsafeBufferPointer { buffer in
            Data(buffer: buffer)
        }
        
        try! interpreter!.copy(metadataData, toInputAt: 1)

        // Run the model inference
        try! interpreter!.invoke()

        // Get the output `Tensor`
        let outputTensor = try! interpreter!.output(at: 0)
        let outputData = outputTensor.data
        let probLst = outputData.withUnsafeBytes { buffer -> [Float] in
            let pointer = buffer.bindMemory(to: Float.self)
            return Array(pointer)
        }

        return probLst
        
    }

}

