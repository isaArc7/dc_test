//
//  RegularDataManager.swift
//  DataCollection
//
//  Created by 汤笑寒 on 2024-09-13.
//

import Foundation

class RegularDataManager {
    public static var shared: RegularDataManager = {
        let mgr = RegularDataManager()
        return mgr
    }()
    
//    func appendAllAvailableSensor() {
//        if GPSProvider.shared.isAvailable && GPSProvider.shared.hasPermission {
//            AllDataSystem.shared.allAvailableParams.append(contentsOf: ["Latitude", "Longitude","Altitude"])
//        } else {
//            GPSProvider.shared.askForPermission { allowed in
//                if allowed {
//                    Log.info("GPS permission is allowed")
//                } else {
//                    Log.warning("Need GPS permission to gain data.")
//                }
//            }
//        }
//        if GyroscopeProvider.shared.isAvailable && GyroscopeProvider.shared.hasPermission {
//            AllDataSystem.shared.allAvailableParams.append(contentsOf: ["Rotation Rate X", "Rotation Rate Y", "Rotation Rate Z"])
//        }
//        if AccelerometerProvider.shared.isAvailable && AccelerometerProvider.shared.hasPermission {
//            AllDataSystem.shared.allAvailableParams.append(contentsOf: ["Accel X","Accel Y","Accel Z"])
//        }
//    }
    
    func startAllSensors() {
        GPSProvider.shared.setup(["accuracy": 1])
        GyroscopeProvider.shared.setup()
        AccelerometerProvider.shared.setup()
        
        GPSProvider.shared.start()
        GyroscopeProvider.shared.start()
        AccelerometerProvider.shared.start()
    }
    
    func stopAllSensors() {
        GPSProvider.shared.stop()
        GyroscopeProvider.shared.stop()
        AccelerometerProvider.shared.stop()
    }
}
