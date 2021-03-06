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
import PXGoogleDirections
import MapKit
import SwiftLocation

class NavigatorHolder{
    var steps : [CLLocationCoordinate2D] = []
    var instructions : [PointOfInterest] = []
    
    init(steps : [CLLocationCoordinate2D], instructions : [PointOfInterest]) {
        self.steps = steps
        self.instructions = instructions
    }
}

class NavigationService{
    var updatedLocations: [CLLocation] = [] // store all the new location updates from Locator.subscribePosition
    
    //for working properly turn the VPN on
    func calculateSteps(destination : Route, request: MKDirections.Request, completion: @escaping (_ route : NavigatorHolder) -> Void){
        request.destination = MKMapItem.init(placemark: MKPlacemark(coordinate: destination.coordinates!))
        request.source = MKMapItem.forCurrentLocation()
        request.transportType = .walking
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            if error != nil {
                print("Error getting directions ", error.debugDescription)
            } else {
                guard let response = response else { return }
                var steps: [CLLocationCoordinate2D] = []
                var instructions : [PointOfInterest] = []
                let route : MKRoute = response.routes[0]
                for stepIndex in 0..<route.polyline.pointCount {
                    let step: MKMapPoint = route.polyline.points()[stepIndex]
                    steps.append(step.coordinate)
                }
                for stepIndex in 0..<route.steps.count{
                    if route.steps[stepIndex].instructions != ""{
                        let poi : PointOfInterest = PointOfInterest(coordinate: route.steps[stepIndex].getLocation().coordinate, title: route.steps[stepIndex].instructions, color: .blue, image : UIImage())
                        instructions.append(poi)
                    }
                }
                let finalRoute : NavigatorHolder = NavigatorHolder(steps: steps, instructions: instructions)
                completion(finalRoute)
            }
        }
    }
    
    func bestLocationEstimate(locations: [CLLocation]) -> CLLocation {
        let sortedLocationEstimates = locations.sorted(by: {
            if $0.horizontalAccuracy == $1.horizontalAccuracy {
                return $0.timestamp > $1.timestamp
            }
            return $0.horizontalAccuracy < $1.horizontalAccuracy
        })
        return sortedLocationEstimates.first!
    }
    
    func convert(scnView: SCNView, coordinate: CLLocationCoordinate2D) -> SCNVector3? {
        let location = bestLocationEstimate(locations: updatedLocations)
        let translation = location.coordinate.coordinatesTranslation(toCoordinate: coordinate)
        return SCNVector3(
            x: scnView.pointOfView!.worldPosition.x + Float(translation.coordinate.longitude),
            y: 0.0,
            z: scnView.pointOfView!.worldPosition.z - Float(translation.coordinate.latitude)
        )
    }
    
    func setNavigation(forRoute route: [CGPoint]) -> [SCNNode] {
        let legsService:LegsService = LegsService();
        let routeLegs = legsService.getLegs(route: route)
        var nodes: [SCNNode] = []
        for index in 0..<routeLegs.count {
            let leg = routeLegs[index]
            for stepIndex in 0..<leg.steps.count{
                let node : ARNode = ARNode()
                let arNode = SCNNode(geometry: node.createNode())
                let position = setPosition(point: leg.steps[stepIndex].point)
                arNode.runAction(SCNAction.repeat(SCNAction.sequence([position]), count: 1))
                nodes.append(arNode)
            }
        }
        return nodes
    }
    
    func setExtraNodes(nodes: [CGPoint], objects : [PointOfInterest]) -> [SCNNode]{
        var scnNodes: [SCNNode] = []
        for index in 0..<objects.count {
            let node : ARNode = ARNode()
            let arNode = SCNNode(geometry: node.createInvisibleNode())
            let position = setPosition(point: nodes[index])
            arNode.runAction(SCNAction.repeat(SCNAction.sequence([position]), count: 1))
            var top : Float = 10
            if objects[index].image.imageAsset != nil{
                let imageNode = node.makeBillboardNode(objects[index].image)
                imageNode.position = SCNVector3Make(0, 4, 0)
                arNode.addChildNode(imageNode)
            }else{
                top = 2
            }
            
            let textNode = node.makeBillboardNode(objects[index].title!.image()!)
            textNode.position = SCNVector3Make(0, top, 0)
            arNode.addChildNode(textNode)
            
            scnNodes.append(arNode)
        }
        return scnNodes
    }
    
    func setPosition(point: CGPoint) -> SCNAction {
        let initialPosition = point.positionInAR
        let initialAngle = Vector.x.angle(with: Vector(0,0))
        let move = SCNAction.move(to: initialPosition, duration: 0.0)
        let rotate = SCNAction.rotateTo(x: 0.0, y: CGFloat(initialAngle), z: 0.0, duration: 0.0)
        let reset = SCNAction.group([move, rotate])
        return reset
    }
}
