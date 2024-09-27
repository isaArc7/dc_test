//
//  AccelerometerProvider.swift
//  IBITripTracking
//
//  Created by Xu Liu on 2023-02-01.
//

import Foundation
import CoreMotion

/// Provide the acceleration information
class AccelerometerProvider: NSObject {
    
    /// This is the motion manager to provider all the necessary data for the accelerator
    private var motion: CMMotionManager = CMMotionManager()
    
    /// This is the private queue for the accelerometer
    private var queue: OperationQueue = OperationQueue()
    
    var parameters = [String: Any]()
    
    public static var shared: AccelerometerProvider = {
        let mgr = AccelerometerProvider()
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
            return self.motion.isAccelerometerAvailable
        }
    }

    /// Setup the parameters for the Accelerometer sensor
    func setup(_ params: [String : Any]? = nil) {
        if let params = params {
            self.parameters = params
        }
        
        // setup the refresh interval from the configuration file
        let update_interval = params?["update_interval"] as? Double ?? 1.0/60.0
        self.motion.accelerometerUpdateInterval = update_interval
        
    }
    
    /// Ask for the sensor to provide the permission
    func askForPermission(completion: ((Bool)->Void)?){
        completion?(true)
        Log.warning("By default, app owns the permission to have the access to accelerometer")
    }
    
    /// Start service
    func start() {
        
        queue.cancelAllOperations()
        queue.maxConcurrentOperationCount = 1
  
        self.motion.startAccelerometerUpdates(to: queue) { accelerometer, error in
            self.accelerometerHandler(accelerometer, error)
        }
    }
    
    /// Stop Service
    func stop() {
        queue.cancelAllOperations()
        self.motion.stopAccelerometerUpdates()
    }
    
    func accelerometerHandler(_ data: CMAccelerometerData?,_ error: Error?){
        if let data = data {
            let x = data.acceleration.x
            let y = data.acceleration.y
            let z = data.acceleration.z
            DispatchQueue.main.async {
                AllDataProvider.shared.allParamValues[.sensor("Accel X")] = x
                AllDataProvider.shared.allParamValues[.sensor("Accel Y")] = y
                AllDataProvider.shared.allParamValues[.sensor("Accel Z")] = z
            }
        }
    }
}
