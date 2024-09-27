//
//  paramHandleType.swift
//  MLDataCollectionApp
//
//  Created by 汤笑寒 on 2024-08-15.
//

import Foundation

enum paramHandleType: String {
    case normalType = "NormalType"
    case engineSpeedType = "EngineSpeedType"
    case throttlePosType = "ThrottlePositionType"
    case commandedAirFuelEqRatioType = "CommandedAirFuelEqRatioType"
    case engineFuelRateType = "EngineFuelRateType"
    case tempType = "TemperatureType"
    case noFormulaType = "NoFormulaType"
    
    func processBiResponse(_ response: [String]) -> Double {
        switch self {
        case .normalType:
            return processNormalType(response)
        case .engineSpeedType:
            return processEngineSpeedType(response)
        case .throttlePosType:
            return processThrottlePosType(response)
        case .commandedAirFuelEqRatioType:
            return processCommandedAirFuelEqRatioType(response)
        case .engineFuelRateType:
            return processEngineFuelRateType(response)
        case .tempType:
            return processTempType(response)
        case .noFormulaType:
            return processNoFormulaType(response)
        }
    }
    
    func binaryToDecimal(_ binaryArray: [String]) -> Int {
        let binaryString = binaryArray.map { $0 }.joined()
        return Int(binaryString, radix: 2) ?? 0
    }
    
    // formula: A
    func processNormalType(_ response: [String]) -> Double {
        return Double(binaryToDecimal(response))
    }
    
    // formula: (256A + B)/4
    func processEngineSpeedType(_ response: [String]) -> Double {
        return 0.25 * Double(binaryToDecimal(response))
    }
    
    // formula: (100/255)A
    func processThrottlePosType(_ response: [String]) -> Double {
        return (100 / 255) * Double(binaryToDecimal(response))
    }
    
    // formula: (2/65536)(256A + B)
    func processCommandedAirFuelEqRatioType(_ response: [String]) -> Double {
        return (2 / 65536) * Double(binaryToDecimal(response))
    }
    
    // formula: (1/20)(256A + B)
    func processEngineFuelRateType(_ response: [String]) -> Double {
        return 0.05 * Double(binaryToDecimal(response))
    }
    
    // formula: A - 40
    func processTempType(_ response: [String]) -> Double {
        return Double(binaryToDecimal(response)) - 40
    }
    
    func processNoFormulaType(_ response: [String]) -> Double {
        Log.warning("\(response)")
        return processNormalType(response)
    }
}
