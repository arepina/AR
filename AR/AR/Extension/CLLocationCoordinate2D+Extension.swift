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


extension CLLocationCoordinate2D : Equatable{
    
    // Equatable implementation
    public static func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
    
    // From here: http://www.movable-type.co.uk/scripts/latlong.html
    // Calculate translation between to coordinates
    func coordinatesTranslation(toCoordinate coordinate: CLLocationCoordinate2D) -> CLLocation {
        let position = CLLocationCoordinate2D(latitude: self.latitude, longitude: coordinate.longitude)
        let sqr: (Double) -> Double = { $0 * $0 }
        var a = sqr(sin((position.latitude - coordinate.latitude).degreesToRadians/2)) + cos(coordinate.latitude.degreesToRadians) * cos(position.latitude.degreesToRadians) * sqr(sin(( position.longitude - coordinate.longitude).degreesToRadians/2))
        let distanceLat = atan2(sqrt(a), sqrt(Double(1) - a)) * Double(6_371_000) * 2
        let dLat: Double = (coordinate.latitude > position.latitude ? 1 : -1) * distanceLat
        a = sqr(sin((position.latitude - self.latitude).degreesToRadians/2)) + cos(self.latitude.degreesToRadians) * cos(position.latitude.degreesToRadians) * sqr(sin((position.longitude - self.longitude).degreesToRadians/2))
        let distanceLon = atan2(sqrt(a), sqrt(Double(1) - a)) * Double(6_371_000) * 2
        let dLon: Double = (self.longitude > position.longitude ? -1 : 1) * distanceLon
        return CLLocation(latitude: dLat, longitude: dLon)
    }
    
    // Calculate the destination point from given point having travelled the given distance (in km), on the given initial bearing (bearing may vary before destination is reached)
    func destinationCalculation(with bearing: Double, and distance: Double) -> CLLocationCoordinate2D {
        let distRadiansLat = distance / 6373000.0  // earth radius in meters latitude
        let distRadiansLong = distance / 5602900.0 // earth radius in meters longitude
        let lat1 = self.latitude.toRadians()
        let lon1 = self.longitude.toRadians()
        let lat2 = asin(sin(lat1) * cos(distRadiansLat) + cos(lat1) * sin(distRadiansLat) * cos(bearing))
        let lon2 = lon1 + atan2(sin(bearing) * sin(distRadiansLong) * cos(lat1), cos(distRadiansLong) - sin(lat1) * sin(lat2))
        return CLLocationCoordinate2D(latitude: lat2.toDegrees(), longitude: lon2.toDegrees())
    }
    
    // Calculate the destination point from given point having travelled the given distance, on the given initial bearing
    static func getIntermediaryLocations(currentLocation: CLLocation, destinationLocation: CLLocation) -> [CLLocationCoordinate2D] {
        var distances = [CLLocationCoordinate2D]()
        let metersIntervalPerNode: Float = 10
        var distance = Float(destinationLocation.distance(from: currentLocation))
        let bearing = currentLocation.bearingToLocation(destinationLocation) // The bearing help to create a rotation transformation to position destinationLocation in the right direction at the currentLocation distance
        while distance > metersIntervalPerNode {
            distance -= metersIntervalPerNode
            let newLocation = currentLocation.coordinate.destinationCalculation(with: Double(bearing), and: Double(distance))
            if !distances.contains(newLocation) {
                distances.append(newLocation)
            }
        }
        return distances
    }
}
