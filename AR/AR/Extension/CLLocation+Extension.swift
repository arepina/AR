//
//  CLLocation+Extension.swift
//  AR
//
//  Created by Анастасия on 03/12/2018.
//  Copyright © 2018 Anastasia. All rights reserved.
//

import Foundation
import CoreLocation
import GLKit
import SceneKit


extension CLLocation {
    
    // Calculate the (initial) bearing between two points, in degrees
    func bearingToLocation(_ destinationLocation: CLLocation) -> Double {
        let lat1 = self.coordinate.latitude.toRadians()
        let lon1 = self.coordinate.longitude.toRadians()
        let lat2 = destinationLocation.coordinate.latitude.toRadians()
        let lon2 = destinationLocation.coordinate.longitude.toRadians()
        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2);
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
        let radiansBearing = atan2(y, x)
        return radiansBearing
    }
    
    static func bestLocationEstimate(locations: [CLLocation]) -> CLLocation {
        let sortedLocationEstimates = locations.sorted(by: {
            if $0.horizontalAccuracy == $1.horizontalAccuracy {
                return $0.timestamp > $1.timestamp
            }
            return $0.horizontalAccuracy < $1.horizontalAccuracy
        })
        return sortedLocationEstimates.first!
    }
}
