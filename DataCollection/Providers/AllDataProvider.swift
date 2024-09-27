//
//  AllDataProvider.swift
//  DataCollection
//
//  Created by 汤笑寒 on 2024-09-13.
//

import Foundation
import SwiftUI

enum Param: Equatable, Hashable {
    case command(OBDIICommand)
    case sensor(String)
}

class AllDataProvider: ObservableObject {
    var OBDIICommandList: [OBDIICommand] = [OBDIICommand.engineSpeed, OBDIICommand.throttlePos, OBDIICommand.vehicleSpeed, OBDIICommand.engineFuelRate, OBDIICommand.commandedAirFuelEqRatio, OBDIICommand.intakeAirTemp, OBDIICommand.intakeManifoldAbsPressure, OBDIICommand.ambientAirTemp]
    
    var RegularParamList: [String] = ["Latitude", "Longitude","Altitude","Rotation Rate X", "Rotation Rate Y", "Rotation Rate Z",
                                          "Accel X","Accel Y","Accel Z"]
    
    @Published var pubAllAvailableParams: [Param] = []
    
    @Published var pubAllMonitoringParams: [Param] = []
    
    var allParamValues: [Param:Double] = [:]
    
    var image: UIImage? = nil
    
    public static var shared: AllDataProvider = {
        let mgr = AllDataProvider()
        return mgr
    }()
    
    func getAllAvailableParams() {
        var copy = [Param]()
        copy.append(contentsOf: self.pubAllAvailableParams)
        
        if !ManageDeviceViewModel.shared.pubIsConnected {
            copy.append(contentsOf: [.sensor("Latitude"), .sensor("Longitude"), .sensor("GPS-Speed"), .sensor("Altitude"), .sensor("MagneticHeading"), .sensor("TrueHeading")])
            if GyroscopeProvider.shared.isAvailable && GyroscopeProvider.shared.hasPermission {
                copy.append(contentsOf: [.sensor("Rotation Rate X"), .sensor("Rotation Rate Y"), .sensor("Rotation Rate Z"), .sensor("RollDegree"), .sensor("PitchDegree"), .sensor("YawDegree")])
            }
            if AccelerometerProvider.shared.isAvailable && AccelerometerProvider.shared.hasPermission {
                copy.append(contentsOf: [.sensor("Accel X"),.sensor("Accel Y"),.sensor("Accel Z")])
            }
            
            DispatchQueue.main.async {
                self.pubAllAvailableParams = copy
            }
            return
        }
        
        OBDIIDataManager.shared.getAllbipidStatus {
            // append all available OBDII sensor
            for command in self.OBDIICommandList {
                if OBDIIDataManager.shared.checkPidAvailability(command: command) == true {
                    copy.append(.command(command))
                }
            }
        
            // append all available Regular sensor
//            GPSProvider.shared.askForPermission { allowed in
//                Log.warning("allowed: \(allowed)")
//                if allowed {
//                    DispatchQueue.main.async {
//                        var copycopy = [Param]()
//                        copycopy.append(contentsOf: copy)
//                        copycopy.append(contentsOf: [.sensor("Latitude"), .sensor("Longitude"), .sensor("GPS-Speed"), .sensor("Altitude"), .sensor("MagneticHeading"), .sensor("TrueHeading")])
//                        self.pubAllAvailableParams = copycopy
//                    }
//                }
//            }
            copy.append(contentsOf: [.sensor("Latitude"), .sensor("Longitude"), .sensor("GPS-Speed"), .sensor("Altitude"), .sensor("MagneticHeading"), .sensor("TrueHeading")])
            
//            if GPSProvider.shared.isAvailable && GPSProvider.shared.hasPermission {
//                copy.append(contentsOf: [.sensor("Latitude"), .sensor("Longitude"), .sensor("GPS-Speed"), .sensor("Altitude"), .sensor("MagneticHeading"), .sensor("TrueHeading")])
//            } else {
//                Log.warning("\(GPSProvider.shared.isAvailable)")
//                Log.warning("\(GPSProvider.shared.hasPermission)")
//                GPSProvider.shared.askForPermission { allowed in
//                    if allowed {
//                        Log.info("GPS permission is allowed")
//                    } else {
//                        Log.warning("Need GPS permission to gain data.")
//                    }
//                }
//            }
            if GyroscopeProvider.shared.isAvailable && GyroscopeProvider.shared.hasPermission {
                copy.append(contentsOf: [.sensor("Rotation Rate X"), .sensor("Rotation Rate Y"), .sensor("Rotation Rate Z"), .sensor("RollDegree"), .sensor("PitchDegree"), .sensor("YawDegree")])
            }
            if AccelerometerProvider.shared.isAvailable && AccelerometerProvider.shared.hasPermission {
                copy.append(contentsOf: [.sensor("Accel X"),.sensor("Accel Y"),.sensor("Accel Z")])
            }
            
            DispatchQueue.main.async {
                self.pubAllAvailableParams = copy
            }
        }
    }
}
