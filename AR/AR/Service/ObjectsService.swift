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

class ObjectsService{    
    
    static func getObjects(fileName : String) -> [PointOfInterest]{
        var objects : [PointOfInterest] = []
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
                    var name = r.value(forKey: "CommonName") as! String
                    let mutableString = NSMutableString(string: name)
                    CFStringTransform(mutableString, nil, kCFStringTransformToLatin, false)
                    name += " \n(" + (mutableString as String) + ")"
                    let geoDict = r.value(forKey: "geoData") as! NSDictionary
                    let coordinates = geoDict.value(forKey: "coordinates") as! NSArray
                    let lat = (coordinates[0] as! NSArray)[1] as! Double
                    let lon = (coordinates[0] as! NSArray)[0] as! Double
                    let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    let ob : PointOfInterest = PointOfInterest(coordinate: coord, title: name, color: nil, image: image)
                    objects.append(ob)
                }
                
            } else {
                print("no file")
            }
        } catch {
            print(error.localizedDescription)
        }
        return objects
    }
}
