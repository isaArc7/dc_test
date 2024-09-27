//
//  GPSProvider.swift
//  IBITripTracking
//
//  Created by Xu Liu on 2023-02-01.
//

import UIKit
import Foundation
import MapKit

/** Provide location information and the parameters that we can config for the output log
 As for the location sensor data i nformation, we can get the sensor data information as below
 ````
  timestamp = the timestamp that system provided for that location when we caputure that data
 ````
 ````
  latitude = the latitude value when we use timestamp above to capture the data
 ````
 ````
  longitude = the longitude value when we use timestamp above to capture the data
 ````
 ````
  altitude =  the altitude value when we use timestamp above to capture the data
 ````
 ````
  speed =   the moving speed related to the ground for current device in m/s
 ````
 
 As for the heading information, we can get the information as below
 ````
 timestamp = the timestamp that system provided for that location when we caputure that data
 ````
 ````
 magneticHeading = The heading in degree related to the magntic north
 ````
 ````
 headingAccuracy = Represents the maximum deviation of where the magnetic heading may differ from the actual geomagnetic heading in degrees. A negative value indicates an invalid heading.
 ````
 ````
 trueNorth =  0.0 - 359.9 degrees, 0 being true North
 ````
*/
internal class GPSProvider: NSObject {
    
    /// This is used to make the callback when the authorization changed for the location.
    private var authorizationChanged: ((Bool)->Void)?
    
    /// This is the location manager to provide all the necessary data for the GPS provider
    private var locationManager: CLLocationManager = CLLocationManager()
    
    public static var shared: GPSProvider = {
        let mgr = GPSProvider()
        return mgr
    }()
    
    var parameters = [String: Any]()
    
    /// Indicate whether the sensor has gotten permission or not
    var hasPermission: Bool = false
    
    /// Notify the upstream why the app has no permission
    var isRejected: Bool = false
    
    /// Indicate the sensor is accessible in terms of the mobile phone
    var isAvailable: Bool {
        get {
            return true
        }
    }
    
//    override init() {
//        super.init()
//
//        checkGPSPermission { hasPermission, reject in
//            DispatchQueue.main.async {
//                self.hasPermission = hasPermission
//                self.isRejected = reject
//            }
//        }
//    }
//
//    func checkGPSPermission(completion: @escaping (Bool, Bool)->()) {
//        let Queue = DispatchQueue(label:"CLLMQueue")
//        Queue.async {
//            if CLLocationManager.locationServicesEnabled() {
//                let status = self.locationManager.authorizationStatus
//
//                switch status {
//                case .authorizedAlways, .authorizedWhenInUse:
//                    completion(true, false)
//                case .denied, .restricted:
//                    completion(false, true)
//                case .notDetermined:
//                    DispatchQueue.main.async {
//                        self.locationManager.requestWhenInUseAuthorization()
//                    }
//                    completion(false, false)
//                @unknown default:
//                    completion(false, false)
//                }
//            } else {
//                completion(false, false)
//            }
//        }
//    }

    /// Setup the parameters for the GPS sensor
    func setup(_ params: [String : Any]? = nil) {
        if let params = params {
            self.parameters = params
        }
        
        locationManager.delegate = self
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        if let accuracyValue = params?["accuracy"] as? Double {
            if accuracyValue == 0.5 {
                locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            }else if accuracyValue == 1 {
                locationManager.desiredAccuracy = kCLLocationAccuracyBest
            }else if accuracyValue == 10 {
                locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            }else if accuracyValue == 100 {
                locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            }else if accuracyValue == 1000 {
                locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
            }else if accuracyValue == 3000 {
                locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
            }
        }
    }
    
    /// Ask for the sensor to provide the permission
    func askForPermission(completion: ((Bool)->Void)?){
        self.authorizationChanged = completion
        DispatchQueue.main.async {
            self.locationManager.requestAlwaysAuthorization()
        }
    }
    
    /// Start service
    func start() {
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }
    
    /// Stop Service
    func stop() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }
    
}


extension GPSProvider: CLLocationManagerDelegate {
    
    /// This capture the location update and output the value out
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for location in locations {
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            let speed = location.speed
            let altitude = location.altitude
            DispatchQueue.main.async {
                AllDataProvider.shared.allParamValues[.sensor("Latitude")] = latitude
                AllDataProvider.shared.allParamValues[.sensor("Longitude")] = longitude
                AllDataProvider.shared.allParamValues[.sensor("GPS-Speed")] = speed
                AllDataProvider.shared.allParamValues[.sensor("Altitude")] = altitude
            }
        }
    }
    
    /// This capture the location heading update
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let magneticHeading = newHeading.magneticHeading
        let trueHeading = newHeading.trueHeading
        DispatchQueue.main.async {
            AllDataProvider.shared.allParamValues[.sensor("MagneticHeading")] = magneticHeading
            AllDataProvider.shared.allParamValues[.sensor("TrueHeading")] = trueHeading
        }
    }
    
    /// This is used to check whether the authorizaiton of the location get changed.
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        var allowed = false
        if CLLocationManager.locationServicesEnabled() {
            let status = locationManager.authorizationStatus
            if status == .authorizedAlways || status == .authorizedWhenInUse {
                allowed = true
            }
        }
        self.authorizationChanged?(allowed)
    }
}
