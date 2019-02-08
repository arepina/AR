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
    var image: UIImage
    
    init(coordinate: CLLocationCoordinate2D, title: String, color: UIColor!, image: UIImage) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle =  "(\(coordinate.latitude),\(coordinate.longitude))"
        self.color = color
        self.image = image
        super.init()
    }    
}
