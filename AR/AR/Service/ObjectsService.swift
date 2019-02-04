//
//  ObjectsService.swift
//  AR
//
//  Created by Анастасия on 07/12/2018.
//  Copyright © 2018 Anastasia. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import MapKit
import CoreLocation
import ARCL

class ObjectsService{    
    
    static func getObjects(fileName : String) -> [Object]{
        var objects : [Object] = []
        var image : UIImage
        if fileName == "museums"{
            image = UIImage(named: "museum")!
        }else{
            image = UIImage(named: "theater")!
        }
        do {
            if let file = Bundle.main.url(forResource: fileName, withExtension: "json") {
                let data = try Data(contentsOf: file)
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                let res = json as! [NSDictionary]
                for r in res{
                    let name = r.value(forKey: "CommonName") as! String
                    let geoDict = r.value(forKey: "geoData") as! NSDictionary
                    let coordinates = geoDict.value(forKey: "coordinates") as! NSArray
                    let lat = (coordinates[0] as! NSArray)[1] as! Double
                    let lon = (coordinates[0] as! NSArray)[0] as! Double
                    let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    let loc = CLLocation(coordinate: coordinate, altitude: 150)
                    let ob : Object = Object(l: loc, t : name, i : image)                    
                    objects.append(ob) // image
                }
                
            } else {
                print("no file")
            }
        } catch {
            print(error.localizedDescription)
        }
        return objects
    }
    
    static func getAnnotations(objects : [Object], color : UIColor) -> [PointOfInterest]{
        var annotations : [PointOfInterest] = []
        for ob in objects{
            let annotation : PointOfInterest = PointOfInterest(coordinate: ob.location.coordinate, title: ob.title, color : color)
            annotations.append(annotation)
        }
        return annotations
    }
}
