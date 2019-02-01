//
//  MKRouteStep+Extension.swift
//  AR
//
//  Created by Анастасия on 03/12/2018.
//  Copyright © 2018 Anastasia. All rights reserved.
//

import Foundation
import MapKit

// Get a CLLocation from a route step
extension MKRoute.Step {
    func getLocation() -> CLLocation {
        return CLLocation(latitude: polyline.coordinate.latitude, longitude: polyline.coordinate.longitude)
    }
}
