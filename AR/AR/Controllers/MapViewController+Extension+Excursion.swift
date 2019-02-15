//
//  MapViewController+Extension+Excursion.swift
//  AR
//
//  Created by Анастасия on 15/02/2019.
//  Copyright © 2019 Anastasia. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit
import SceneKit
import ARKit
import MapKit
import SwiftLocation

extension MapViewController{
    @IBAction func museumClick(_ sender: UIButton) {
        let toLoad : Bool = sender.layer.shadowColor != UIColor.green.cgColor
        clearObjects(sender)
        if toLoad {
            sender.layer.shadowColor = UIColor.green.cgColor
            sender.layer.shadowOffset = CGSize(width: 2, height: 2)
            sender.layer.shadowOpacity = 1.0
            sender.layer.shadowRadius = 0.0
            navigationService.updatedLocations.append(SwiftLocation.Locator.currentLocation!)
            let objects = ObjectsService.getObjects(fileName: "museums") // 54 objects + 1 extra for test purposes
            let nodes = objects
                .map { navigationService.convert(scnView: self.sceneView, coordinate: $0.coordinate)} // convert all the coordinates to the AR suitable
                .compactMap { $0 } // remove the nils
                .map { CGPoint(position: $0)} // combine the points
            for annotation in objects{
                map.addAnnotation(annotation)
                poiHolder.annotationMuseums.append(annotation)
            }
            museumNodes = navigationService.setExtraNodes(nodes: nodes, objects: objects)// AR
        }
    }
    
    @IBAction func theatersClick(_ sender: UIButton) {
        let toLoad : Bool = sender.layer.shadowColor != UIColor.green.cgColor
        clearObjects(sender)
        if toLoad {
            sender.layer.shadowColor = UIColor.green.cgColor
            sender.layer.shadowOffset = CGSize(width: 2, height: 2)
            sender.layer.shadowOpacity = 1.0
            sender.layer.shadowRadius = 0.0
            navigationService.updatedLocations.append(SwiftLocation.Locator.currentLocation!)
            let objects = ObjectsService.getObjects(fileName: "theaters")
            let nodes = objects
                .map { navigationService.convert(scnView: self.sceneView, coordinate: $0.coordinate)} // convert all the coordinates to the AR suitable
                .compactMap { $0 } // remove the nils
                .map { CGPoint(position: $0)} // combine the points
            for annotation in objects{
                map.addAnnotation(annotation)
                poiHolder.annotationTheaters.append(annotation)
            }
            theaterNodes = navigationService.setExtraNodes(nodes: nodes, objects : objects)// AR
        }
    }
    
    func clearObjects(_ sender : UIButton!){
        // remove all the objects from scene
        sender.layer.shadowColor = UIColor.clear.cgColor
        sender.layer.shadowOffset = CGSize(width: 0, height: 0)
        sender.layer.shadowOpacity = 0.0
        sender.layer.shadowRadius = 0.0
        clearButtons()
        museumNodes.removeAll()
        theaterNodes.removeAll()
        for ob in poiHolder.annotationTheaters{
            map.removeAnnotation(ob)
        }
        for ob in poiHolder.annotationMuseums{
            map.removeAnnotation(ob)
        }
    }
}
