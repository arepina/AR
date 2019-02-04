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
    
    static func bearing(startLocation: CLLocation, destinationLocation: CLLocation) -> Double {
        let lat1 = startLocation.coordinate.latitude.degreesToRadians
        let lon1 = startLocation.coordinate.longitude.degreesToRadians
        let lat2 = destinationLocation.coordinate.latitude.degreesToRadians
        let lon2 = destinationLocation.coordinate.longitude.degreesToRadians
        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2);
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
        let radiansBearing = atan2(y, x)
        return radiansBearing
    }
    
    //todo!!!
//    func correctionAngleByBearing(e1: CLLocation, e2: CLLocation) -> Double {
//        let calcE2 = e1.translatedLocation(with: e2.position)
//        return CLLocationCoordinate2D.bearing(startLocation: e1, destinationLocation: calcE2) - CLLocationCoordinate2D.bearing(e1, e2)
//    }
    
    // Calculate translation between to coordinates
    func coordinatesTranslation(toCoordinate coordinate: CLLocationCoordinate2D) -> CLLocation {
        let position = CLLocationCoordinate2D(latitude: self.latitude, longitude: coordinate.longitude)
        let distanceLat = haversine(coordinate.latitude, coordinate.longitude, position.latitude, position.longitude)
        let dLat: Double = (coordinate.latitude > position.latitude ? 1 : -1) * distanceLat
        let distanceLon = haversine(self.latitude, self.longitude, position.latitude, position.longitude)
        let dLon: Double = (longitude > position.longitude ? -1 : 1) * distanceLon
        return CLLocation(latitude: dLat, longitude: dLon)
    }
    
//    // Calculate the destination point from given point having travelled the given distance (in km), on the given initial bearing (bearing may vary before destination is reached)
//    func destinationCalculation(with bearing: Double, and distance: Double) -> CLLocationCoordinate2D {
//        let distRadiansLat = distance / 6373000.0  // earth radius in meters latitude
//        let distRadiansLong = distance / 5602900.0 // earth radius in meters longitude
//        let lat1 = self.latitude.toRadians()
//        let lon1 = self.longitude.toRadians()
//        let lat2 = asin(sin(lat1) * cos(distRadiansLat) + cos(lat1) * sin(distRadiansLat) * cos(bearing))
//        let lon2 = lon1 + atan2(sin(bearing) * sin(distRadiansLong) * cos(lat1), cos(distRadiansLong) - sin(lat1) * sin(lat2))
//        return CLLocationCoordinate2D(latitude: lat2.toDegrees(), longitude: lon2.toDegrees())
//    }
//

//
//    // Calculate the destination point from given point having travelled the given distance, on the given initial bearing
//    static func getIntermediaryLocations(currentLocation: CLLocation, destinationLocation: CLLocation) -> [CLLocationCoordinate2D] {
//        var distances = [CLLocationCoordinate2D]()
//        let metersIntervalPerNode: Float = 5
//        var distance = Float(destinationLocation.distance(from: currentLocation))
//        let bearing = bearingToLocation(startLocation: currentLocation, destinationLocation: destinationLocation) // The bearing help to create a rotation transformation to position destinationLocation in the right direction at the currentLocation distance
//        while distance > metersIntervalPerNode {
//            distance -= metersIntervalPerNode
//            let newLocation = currentLocation.coordinate.destinationCalculation(with: Double(bearing), and: Double(distance))
//            if !distances.contains(newLocation) {
//                distances.append(newLocation)
//            }
//        }
//        return distances
//    }
}
