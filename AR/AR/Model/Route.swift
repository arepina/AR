//
//  Route.swift
//  AR
//
//  Created by Анастасия on 27/11/2018.
//  Copyright © 2018 Anastasia. All rights reserved.
//


import Foundation
import CoreLocation

class Route{
    var place:String = ""
    var coordinates:CLLocationCoordinate2D?
    var key:String = ""
    
    init(p:String, c:String, k:String){
        place = p
        let separated = c.components(separatedBy: ";")
        let latitude = Double(String(separated[0]))!
        let longitude = Double(String(separated[1]))!
        coordinates = CLLocationCoordinate2D(latitude: CLLocationDegrees(exactly: latitude)!
            , longitude: CLLocationDegrees(exactly: longitude)!)
        key = k
    }
}
