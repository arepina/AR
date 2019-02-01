//
//  NavigationService.swift
//  AR
//
//  Created by Анастасия on 05/12/2018.
//  Copyright © 2018 Anastasia. All rights reserved.
//

import Foundation
import CoreLocation
import SceneKit
import ARKit
import MapKit
import SwiftLocation
import ARCL

class NavigationService{
    var updatedLocations: [CLLocation] = [] // store all the new location updates from Locator.subscribePosition
    
    func getLocations() -> [CLLocation] {
        return updatedLocations
    }
    
    func calculateSteps(destination : Route, request: MKDirections.Request, completion: @escaping (MKRoute) -> Void){
        request.destination = MKMapItem.init(placemark: MKPlacemark(coordinate: destination.coordinates!))
        request.source = MKMapItem.forCurrentLocation()
        request.requestsAlternateRoutes = false
        request.transportType = .walking
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            if error != nil {
                print("Error getting directions")
            } else {
                guard let response = response else { return }
                completion(response.routes[0])
            }
        }
    }
    
    func calculateLeg(for index: Int, and tripStep: MKRoute.Step, and steps : [MKRoute.Step] ) -> [CLLocationCoordinate2D] {
        var previousLocation : CLLocation
        if(index == 0) // intermediary coordinates for first route step
        {
            previousLocation = CLLocation(latitude: SwiftLocation.Locator.currentLocation!.coordinate.latitude, longitude: SwiftLocation.Locator.currentLocation!.coordinate.longitude)
        }else{ // intermediary coordinates for route step that is not first
            previousLocation = CLLocation(latitude: steps[index - 1].polyline.coordinate.latitude, longitude: steps[index - 1].polyline.coordinate.longitude)
        }
        let nextLocation = CLLocation(latitude: tripStep.polyline.coordinate.latitude, longitude: tripStep.polyline.coordinate.longitude)
        let leg = CLLocationCoordinate2D.getIntermediaryLocations(currentLocation: previousLocation, destinationLocation: nextLocation)
        return leg
    }
    
    func addNodes(legs: [[CLLocationCoordinate2D]], steps: [MKRoute.Step], sceneView: SceneLocationView!) -> [ARNode]{
        var nodes : [ARNode] = []
        for step in steps { // the main points
            let locationTransform = Matrix.transformMatrix(for: matrix_identity_float4x4, originLocation: SwiftLocation.Locator.currentLocation!, location: step.getLocation())
            let position = SCNVector3Make(locationTransform.columns.3.x, locationTransform.columns.3.y, locationTransform.columns.3.z)
            let distance = step.getLocation().distance(from: SwiftLocation.Locator.currentLocation!)
            let scale = 100 / Float(distance)
            let stepAnchor = ARAnchor(transform: locationTransform)
            let sphere = ARNode(location: step.getLocation(), anchor: stepAnchor, title: step.instructions, distance: distance)
            sphere.scale = SCNVector3(x: scale, y: scale, z: scale)
            sphere.position = position
            sphere.addNode(with: 0.3, and: .green, and: step.instructions)
            nodes.append(sphere)
            sceneView.session.add(anchor: stepAnchor)
            sceneView.scene.rootNode.addChildNode(sphere)
        }
        let coordinates = legs.flatMap { $0 } // all the legs together
        let intermediaryLocations = coordinates.map { CLLocation(latitude: $0.latitude, longitude: $0.longitude) } // all the intermediary locations in the legs together
        for location in intermediaryLocations{
            let locationTransform = Matrix.transformMatrix(for: matrix_identity_float4x4, originLocation: SwiftLocation.Locator.currentLocation!, location: location)
            let distance = location.distance(from: SwiftLocation.Locator.currentLocation!)
            let scale = 100 / Float(distance)
            let position = SCNVector3Make(locationTransform.columns.3.x, locationTransform.columns.3.y, locationTransform.columns.3.z)
            let stepAnchor = ARAnchor(transform: locationTransform)
            let sphere = ARNode(location: location, anchor: stepAnchor, title: "", distance: distance)
            sphere.scale = SCNVector3(x: scale, y: scale, z: scale)
            sphere.position = position
            sphere.addSphere(with: 0.25, and: .red)
            nodes.append(sphere)
            sceneView.session.add(anchor: stepAnchor)
            sceneView.scene.rootNode.addChildNode(sphere)
        }
        return nodes
    }
    
    func updateNodes(nodes: [ARNode]) {
        //when user is moving, the nodes postion may change, so update them
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            if updatedLocations.count > 0 {
                let startLocation = CLLocation.bestLocationEstimate(locations: updatedLocations) // choose the best out of stores
                for node in nodes {
                    let translation = Matrix.transformMatrix(for: matrix_identity_float4x4, originLocation: startLocation, location: node.location)
                    let position = SCNVector3Make(translation.columns.3.x, translation.columns.3.y, translation.columns.3.z)
                    let distance = node.location.distance(from: startLocation)
                    DispatchQueue.main.async {
                        let scale = 100 / Float(distance)
                        node.scale = SCNVector3(x: scale, y: scale, z: scale)
                        node.anchor = ARAnchor(transform: translation)
                        node.position = position
                    }
                }
            }
            SCNTransaction.commit()
    }
}
