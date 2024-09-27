//
//  OBDIIDataManager.swift
//  DataCollection
//
//  Created by 汤笑寒 on 2024-09-13.
//

import Foundation

class OBDIIDataManager {
    var pidStatusCommands: [OBDIICommand] = [OBDIICommand.check1to32pid, OBDIICommand.check33to64pid, OBDIICommand.check65to96pid, OBDIICommand.check97to128pid, OBDIICommand.check129to160pid] //in my car, 160 has bit 0.
    
    var paramHandleTypes: [String: paramHandleType] = [OBDIICommand.engineSpeed.name: paramHandleType.engineSpeedType,
                                                       OBDIICommand.throttlePos.name: paramHandleType.throttlePosType,
                                                       OBDIICommand.vehicleSpeed.name: paramHandleType.normalType,
                                                       OBDIICommand.engineFuelRate.name: paramHandleType.engineFuelRateType,
                                                       OBDIICommand.commandedAirFuelEqRatio.name: paramHandleType.commandedAirFuelEqRatioType,
                                                       OBDIICommand.intakeAirTemp.name: paramHandleType.tempType,
                                                       OBDIICommand.intakeManifoldAbsPressure.name: paramHandleType.noFormulaType,
                                                       OBDIICommand.ambientAirTemp.name: paramHandleType.tempType]
    
    var commandRawResponse: [String: [String]] = [:]
    
    var pidStatuses: [String: [String]] = [:]
    
    var pidStatusCommandIndex: Int = 0
    
    var monitoredParamIndex: Int = 0
    
    var monitoredPids: [OBDIICommand] = []
    
    public static var shared: OBDIIDataManager = {
        let mgr = OBDIIDataManager()
        return mgr
    }()
    
    func getAllbipidStatus(completion: @escaping ()->()) {
        recursiveGetHexPidStatus(completion: completion)
    }
    
    // use recursive because, if the first command didn't finish sending, it will block the second and third command.
    func recursiveGetHexPidStatus(completion: @escaping ()->()) {
        let command = OBDIIDataManager.shared.pidStatusCommands[pidStatusCommandIndex]
        OBDIIScanner.shared.sendCommand(command, timeout: 10) { result in
            switch result {
            case .success(let responses):
                
                OBDIIDataManager.shared.commandRawResponse[command.name] = responses
                Log.info("Successfully gained response from \(command). Responses: \(responses)")
                self.pidStatusHexToBi(command: command)
                
                if self.pidStatusCommandIndex == OBDIIDataManager.shared.pidStatusCommands.count - 1 {
                    Log.info("Gained response from checking pid 1 to pid 160.")
                    completion()
                }
                
                if self.pidStatusCommandIndex < OBDIIDataManager.shared.pidStatusCommands.count - 1 {
                    self.pidStatusCommandIndex += 1
                    self.recursiveGetHexPidStatus(completion: completion)
                }
            case .failure(let error):
                Log.error("Failed to gain response from \(command). Error: \(error)")
            }
        }
    }
    
    func pidStatusHexToBi(command: OBDIICommand) -> Void {
        var statusList: [String] = []
        // could contain responses from several ecu
        if let responses = OBDIIDataManager.shared.commandRawResponse[command.name] {
            for i in 0..<responses.count {
                var response = responses[i]
                // find engine ecu
                if response.prefix(11) == "18 DA F1 58" || response.prefix(3) == "7E8" {
                    // extract part after 41 00
                    if let range = response.range(of: "41") {
                        // 41 00, 41 20
                        // 3 for " 00" or " 20", 1 for the next index to become start
                        let startIndex = response.index(range.upperBound, offsetBy: 3 + 1)
                        response = String(response[startIndex...])
                    } else {
                        Log.error("Didn't find 41 in get1to32pid's response")
                    }
                    
                    let hexComponents = response.split(separator: " ") // ["BE", "3C"]
                    assert(hexComponents.count == 4)
                    for hex in hexComponents {
                        guard let dec = Int(hex, radix: 16) else { // [190] / [60]
                            Log.error("Can't convert hex \(hex) to dec.")
                            return
                        }
                        let bi = String(dec, radix: 2) // ["10111110"] / ["111100"]
                        let paddedbi = String(repeating: "0", count: 8 - bi.count) + bi // ["00111100"]
                        // String($0) -> ["0", "0", "1", "1", "1", "1", "0", "0"]
                        // Int(String($0)) -> [0, 0, 1, 1, 1, 1, 0, 0]
                        let Arr = paddedbi.compactMap { String($0)}
                        statusList.append(contentsOf: Arr)
                    }
                    Log.info("Have record pidStatuses for \(command).")
                }
            }
        } else { return }
        OBDIIDataManager.shared.pidStatuses[command.name] = statusList
    }
    
    func checkPidAvailability(command: OBDIICommand) -> Bool {
        let pidInDec = command.pidInDec
        if pidInDec == -1 { return false }
        let quotient = pidInDec / 32
        // pid: 1. 1 % 32 = 1. We look at index 0.
        let index = pidInDec % 32 - 1
        var lst: [String]?
        switch quotient {
        case 0:
            lst = OBDIIDataManager.shared.pidStatuses[OBDIICommand.check1to32pid.name]
        case 1:
            lst = OBDIIDataManager.shared.pidStatuses[OBDIICommand.check33to64pid.name]
        case 2:
            lst = OBDIIDataManager.shared.pidStatuses[OBDIICommand.check65to96pid.name]
        case 3:
            lst = OBDIIDataManager.shared.pidStatuses[OBDIICommand.check97to128pid.name]
        case 4:
            lst = OBDIIDataManager.shared.pidStatuses[OBDIICommand.check129to160pid.name]
        default:
            lst = OBDIIDataManager.shared.pidStatuses[OBDIICommand.check1to32pid.name]
        }
        Log.info("Command: \(command). lst: \(String(describing: lst))")
        if lst == nil || lst == [] {
            Log.error("lst for \(command) is either nil or empty.")
            return false
        }
        if Int((lst?[index])!) == 1 {
            return true
        }
        return false
    }
    
    // check if author selected params are there
//    func appendAvailablePids(selectedCommandList: [OBDIICommand]) {
//        var availablePidsCopy = [String]()
//        availablePidsCopy.append(contentsOf: AllDataProvider.shared.allAvailableParams)
//
//        for command in selectedCommandList {
//            let pidInDec = command.pidInDec
//            if pidInDec == -1 { return }
//            let quotient = pidInDec / 32
//            // pid: 1. 1 % 32 = 1. We look at index 0.
//            let index = pidInDec % 32 - 1
//            var lst: [String]?
//            switch quotient {
//            case 0:
//                lst = OBDIIDataManager.shared.pidStatuses[OBDIICommand.check1to32pid.name]
//            case 1:
//                lst = OBDIIDataManager.shared.pidStatuses[OBDIICommand.check33to64pid.name]
//            case 2:
//                lst = OBDIIDataManager.shared.pidStatuses[OBDIICommand.check65to96pid.name]
//            case 3:
//                lst = OBDIIDataManager.shared.pidStatuses[OBDIICommand.check97to128pid.name]
//            case 4:
//                lst = OBDIIDataManager.shared.pidStatuses[OBDIICommand.check129to160pid.name]
//            default:
//                lst = OBDIIDataManager.shared.pidStatuses[OBDIICommand.check1to32pid.name]
//            }
//            Log.info("Command: \(command). lst: \(String(describing: lst))")
//            if lst == nil {
//                Log.error("lst for \(command) is nil.")
//                return
//            }
//            if Int((lst?[index])!) == 1 {
//                OBDIIDataManager.shared.availablePids.append(command)
//                availablePidsCopy.append(command.name)
//            }
//        }
//        AllDataProvider.shared.allAvailableParams = availablePidsCopy
//    }
    
    func getResponses(completion: @escaping ()->()) {
        if CameraViewModel.shared.pubIsCollecting {
            monitoredParamIndex = 0
            recursiveGetResponses(completion: completion)
        }
    }
    
    func recursiveGetResponses(completion: @escaping ()->()) {
        let command = OBDIIDataManager.shared.monitoredPids[monitoredParamIndex]
        
        getProcessedResponse(command: command) {
            if self.monitoredParamIndex < OBDIIDataManager.shared.monitoredPids.count - 1 {
                self.monitoredParamIndex += 1
                self.recursiveGetResponses(completion: completion)
            } else {
                self.getResponses(completion: completion)
            }
        }
    }
    
    func getProcessedResponse(command: OBDIICommand, completion: @escaping ()->()) {
        OBDIIScanner.shared.sendCommand(command, timeout: 10) { result in
            switch result {
            case .success(let responses):
                OBDIIDataManager.shared.commandRawResponse[command.name] = responses
                Log.info("Successfully get raw response from command \(command.name). Response: \(responses)")
                
                self.processParamValue(command: command) {
                    Log.info("Have processed param values.")
                    completion()
                }
            case .failure(let error):
                Log.info("Fail to get the response for the command \(command.name). Error: \(error)")
            }
        }
    }
    
    func processParamValue(command: OBDIICommand, completion: @escaping ()->()) {
        let rawResponses = OBDIIDataManager.shared.commandRawResponse[command.name]!
        let bits = extractBits(rawResponses)
        let paramHandleType = OBDIIDataManager.shared.paramHandleTypes[command.name]
        let value = paramHandleType?.processBiResponse(bits)
        AllDataProvider.shared.allParamValues[.command(command)] = value
        Log.info("command: \(command). paramvalue: \(value)")
        completion()
    }
    
    func hexToBi(_ response: String) -> [String] {
            var res: [String] = []
            let hexComponents = response.split(separator: " ") // ["BE", "3C"]
            for hex in hexComponents {
                guard let dec = Int(hex, radix: 16) else { // [190] / [60]
                    Log.error("Can't convert hex \(hex) to dec.")
                    return []
                }
                let bi = String(dec, radix: 2) // ["10111110"] / ["111100"]
                let paddedbi = String(repeating: "0", count: 8 - bi.count) + bi // ["00111100"]
                // String($0) -> ["0", "0", "1", "1", "1", "1", "0", "0"]
                // Int(String($0)) -> [0, 0, 1, 1, 1, 1, 0, 0]
                let Arr = paddedbi.compactMap { String($0)}
                res.append(contentsOf: Arr)
            }
            return res
        }
    
    func extractBits(_ responses: [String]) -> [String] {
        for i in 0..<responses.count {
            var response = responses[i]
            // find engine ecu
            if response.prefix(11) == "18 DA F1 58" {
                // extract part after 41 0C, before AA AA
                if let leftrange = response.range(of: "41") {
                    let startIndex = response.index(leftrange.upperBound, offsetBy: 3 + 1) // 41 0C, 41 1E
                    response = String(response[startIndex...])
                } else {
                    Log.error("Error from finding 41 in the response")
                }
                let bits = hexToBi(response)
                return bits
            }
        }
        return []
    }
}
