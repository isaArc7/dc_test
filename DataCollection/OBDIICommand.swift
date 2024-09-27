//
//  OBDIICommand.swift
//  MLDataCollectionApp
//
//  Created by 汤笑寒 on 2024-07-24.
//

import Foundation

public enum OBDIICommand: String {
    case reset = "ATZ"
    case disableEcho = "ATE0"
    case autoSelectProtocol = "ATSP0"
    case headOn = "ATH1"
    case check1to32pid = "0100"
    case check33to64pid = "0120"
    case check65to96pid = "0140"
    case check97to128pid = "0160"
    case check129to160pid = "0180"
    case check161to192pid = "01A0"
    case check193to224pid = "01C0"
    //12 engine speed
    //13 vehicle speed
    //17 throttle position
    //68 Commanded Air-Fuel Equivalence Ratio
    //94 Engine fuel rate
    case engineSpeed = "010C"
    case vehicleSpeed = "010D"
    case throttlePos = "0111"
    case commandedAirFuelEqRatio = "0144"
    case engineFuelRate = "015E"
    case intakeAirTemp = "010F"
    case intakeManifoldAbsPressure = "0187"
    case ambientAirTemp = "0146"
    
    var name: String {
        switch self {
        case .reset:
            return "Reset"
        case .disableEcho:
            return "DisableEcho"
        case .autoSelectProtocol:
            return "AutoSelectProtocol"
        case .headOn:
            return "HeadOn"
        case .check1to32pid:
            return "Check1to32pid"
        case .check33to64pid:
            return "Check33to64pid"
        case .check65to96pid:
            return "Check65to96pid"
        case .check97to128pid:
            return "Check97to128pid"
        case .check129to160pid:
            return "Check129to160pid"
        case .check161to192pid:
            return "Check161to192pid"
        case .check193to224pid:
            return "Check193to224pid"
        case .engineSpeed:
            return "EngineSpeed"
        case .vehicleSpeed:
            return "VehicleSpeed"
        case .throttlePos:
            return "ThrottlePosition"
        case .commandedAirFuelEqRatio:
            return "CommandedAirFuelEqRatio"
        case .engineFuelRate:
            return "EngineFuelRate"
        case .intakeAirTemp:
            return "IntakeAirTemperature"
        case .intakeManifoldAbsPressure:
            return "IntakeManifoldAbsolutePressure"
        case .ambientAirTemp:
            return "AmbientAirTemperature"
        }
    }

    var pidInDec: Int {
        switch self {
        case .reset:
            return -1
        case .disableEcho:
            return -1
        case .autoSelectProtocol:
            return -1
        case .headOn:
            return -1
        case .check1to32pid:
            return 0
        case .check33to64pid:
            return 32
        case .check65to96pid:
            return 64
        case .check97to128pid:
            return 96
        case .check129to160pid:
            return 128
        case .check161to192pid:
            return 160
        case .check193to224pid:
            return 192
        case .engineSpeed:
            return 12
        case .vehicleSpeed:
            return 13
        case .intakeAirTemp:
            return 15
        case .throttlePos:
            return 17
        case .commandedAirFuelEqRatio:
            return 68
        case .engineFuelRate:
            return 94
        case .intakeManifoldAbsPressure:
            return 135
        case .ambientAirTemp:
            return 70
        }
    }
}
