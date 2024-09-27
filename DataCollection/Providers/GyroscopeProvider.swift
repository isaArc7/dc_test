//
//  GyroscopeProvider.swift
//  IBITripTracking
//
//  Created by Xu Liu on 2023-02-01.
//

import Foundation
import CoreMotion

/// Provide device rotation and position information
class GyroscopeProvider: NSObject {
    
    /// This is the motion manager to provider all the necessary data for the gyroscope
    private var motion: CMMotionManager = CMMotionManager()
    
    /// This is the private queue for the gyroscope
    private var GyroQueue: OperationQueue = OperationQueue()
    
    /// This is the private queue for the device motion
    private var DMQueue: OperationQueue = OperationQueue()
    
    var parameters = [String: Any]()
    
    public static var shared: GyroscopeProvider = {
        let mgr = GyroscopeProvider()
        return mgr
    }()
    
    /// Indicate whether the sensor has gotten permission or not
    var hasPermission: Bool {
        get {
            // CMMotionManager always has permission to access the motion data. No need to check the permisison with user.
            return true
        }
    }
    
    /// Notify the upstream why the app has no permission
    var isRejected: Bool {
        get {
            // There is no way for user to reject the CMMotionManager
            return false
        }
    }
    
    /// Indicate the sensor is accessible in terms of the mobile phone
    var isAvailable: Bool {
        get {
            return self.motion.isGyroAvailable
        }
    }

    /// Setup the parameters for the Gyroscope sensor
    func setup(_ params: [String : Any]? = nil) {
        if let params = params {
            self.parameters = params
        }
        
        // setup the refresh interval from the configuration file
        let update_interval = params?["update_interval"] as? Double ?? 1.0/60.0
        self.motion.gyroUpdateInterval = update_interval
        self.motion.deviceMotionUpdateInterval = update_interval
    }
    
    /// Ask for the sensor to provide the permission
    func askForPermission(completion: ((Bool)->Void)?){
        completion?(true)
        Log.warning("By default, app owns the permission to have the access to gyroscope")
    }
    
    /// Start service
    func start() {
        GyroQueue.cancelAllOperations()
        DMQueue.cancelAllOperations()
        GyroQueue.maxConcurrentOperationCount = 1
        DMQueue.maxConcurrentOperationCount = 1
        self.motion.startGyroUpdates(to: GyroQueue) { gyro, error in
            self.gyroHandler(gyro, error)
        }
        
        self.motion.startDeviceMotionUpdates(to: DMQueue) { dm, error in
            self.dmHandler(dm, error)
        }
    }
    
    /// Stop Service
    func stop() {
        GyroQueue.cancelAllOperations()
        DMQueue.cancelAllOperations()
        self.motion.stopGyroUpdates()
        self.motion.stopDeviceMotionUpdates()
    }

    func gyroHandler(_ data: CMGyroData?,_ error: Error?){
        if let data = data {
            let x = data.rotationRate.x
            let y = data.rotationRate.y
            let z = data.rotationRate.z
            DispatchQueue.main.async {
                AllDataProvider.shared.allParamValues[.sensor("Rotation Rate X")] = x
                AllDataProvider.shared.allParamValues[.sensor("Rotation Rate Y")] = y
                AllDataProvider.shared.allParamValues[.sensor("Rotation Rate Z")] = z
            }
        }
    }
    
    func dmHandler(_ data: CMDeviceMotion?, _ error: Error?) {
        if let data = data {
            let roll = data.attitude.roll
            let pitch = data.attitude.pitch
            let yaw = data.attitude.yaw
            
            let rolldegree = roll * 180 / .pi
            let pitchdegree = pitch * 180 / .pi
            let yawdegree = yaw * 180 / .pi
            DispatchQueue.main.async {
                AllDataProvider.shared.allParamValues[.sensor("RollDegree")] = rolldegree
                AllDataProvider.shared.allParamValues[.sensor("PitchDegree")] = pitchdegree
                AllDataProvider.shared.allParamValues[.sensor("YawDegree")] = yawdegree
            }
        }
    }
}
