//
//  FirebaseActions.swift
//  AR
//
//  Created by Анастасия on 26/11/2018.
//  Copyright © 2018 Anastasia. All rights reserved.
//

import Firebase
import FirebaseDatabase
import CoreLocation
import UIKit

class FirebaseService{
    static var ref: DatabaseReference = Database.database().reference() // Firebase DB
    
    static func addRoute(userID : String, coordinate : CLLocationCoordinate2D, placeName : String){
        let lat:Double = coordinate.latitude
        let lon:Double = coordinate.longitude
        let coordinates:String = String(lat) + ";" + String(lon)
        let firebaseNewPlace = self.ref.child("routes").child(userID).childByAutoId()
        firebaseNewPlace.child("coordinates").setValue(coordinates)
        firebaseNewPlace.child("place").setValue(placeName)
    }
    
    static func removeRoute(userID : String, key : String){
        let routeRef = self.ref.child("routes").child(userID).child(key)
        routeRef.removeValue()
    }
    
    static func getAllRoutes(userID : String, callback : @escaping ([Route])->Void) {
        self.ref.child("routes").child(userID).observeSingleEvent(of: .value, with: { snapshot in
            var routes : [Route] = []
            for child in snapshot.children {
                let snap = child as! DataSnapshot
                let dict = snap.value as! [String: Any]
                let coordinates = dict["coordinates"] as! String
                let place = dict["place"] as! String
                let key = snap.key
                routes.append(Route(p: place, c: coordinates, k: key))
            }
            callback(routes)
        })
    }
}

