//
//  CLLocationCoordinate2D+Extension.swift
//  AR
//
//  Created by Анастасия on 03/12/2018.
//  Copyright © 2018 Anastasia. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit
import SceneKit

extension CLLocationCoordinate2D {
    
    public func haversine(_ lat1: Double, _ lon1: Double, _ lat2: Double, _ lon2: Double) -> Double {
        let sqr: (Double) -> Double = { $0 * $0 }
        let R = Double(6_371_000)
        let phi_1 = lat1.degreesToRadians
        let phi_2 = lat2.degreesToRadians
        let dPhi = (lat2 - lat1).degreesToRadians
        let dLmb = (lon2 - lon1).degreesToRadians
        let a = sqr(sin(dPhi/2)) + cos(phi_1) * cos(phi_2) * sqr(sin(dLmb/2))
        let c: Double = 2 * atan2(sqrt(a), sqrt(Double(1) - a))
        return R * c
    }
    
    func bearing(location: CLLocation) -> Double {
        let lat1 = self.latitude.degreesToRadians
        let lon1 = self.longitude.degreesToRadians
        let lat2 = location.coordinate.latitude.degreesToRadians
        let lon2 = location.coordinate.longitude.degreesToRadians
        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2);
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
        let radiansBearing = atan2(y, x)
        return radiansBearing
    }
    
    func coordinatesTranslation(toCoordinate coordinate: CLLocationCoordinate2D) -> CLLocation {
        let position = CLLocationCoordinate2D(latitude: self.latitude, longitude: coordinate.longitude)
        let distanceLat = haversine(coordinate.latitude, coordinate.longitude, position.latitude, position.longitude)
        let dLat: Double = (coordinate.latitude > position.latitude ? 1 : -1) * distanceLat
        let distanceLon = haversine(self.latitude, self.longitude, position.latitude, position.longitude)
        let dLon: Double = (longitude > position.longitude ? -1 : 1) * distanceLon
        
        let bearing = self.bearing(location: CLLocation(latitude: dLat, longitude: dLon))
        _ = dLat * cos(bearing)
        _ = dLon * sin(bearing)
        //print(bearing,coordinate.latitude > position.latitude ? 1 : -1,  longitude > position.longitude ? -1 : 1)
        
        return CLLocation(latitude: dLat, longitude: dLon)
    }
}
