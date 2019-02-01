//
//  PointOfInterest.swift
//  AR
//
//  Created by Анастасия on 03/12/2018.
//  Copyright © 2018 Anastasia. All rights reserved.
//

import Foundation
import MapKit

class PointOfInterest: NSObject, MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D
    var title: String?    
    var subtitle: String?
    var color: UIColor!
    
    init(coordinate: CLLocationCoordinate2D, title: String, color: UIColor!) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle =  "(\(coordinate.latitude),\(coordinate.longitude))"
        self.color = color
        super.init()
    }    
}
