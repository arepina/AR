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
    
    func getLegs(route: [CGPoint]) -> [Leg] {
        guard route.count >= 2 else { return [] }
        var legs: [Leg] = []
        var currentLeg: Leg = Leg(steps: [])
        let legsCount = Array(zip(route, route.skip(1))).count
        var currentLegIndex = 0
        var offsetInLeg: CGFloat = 0.0
        var lengthTailFromPrevLeg: CGFloat? = nil
        while currentLegIndex < legsCount { // iterate all the route legs
            let leg = CGLine(point1: route[currentLegIndex], point2: route[currentLegIndex + 1])
            var stepStart: CGPoint
            var stepEnd: CGPoint
            if let lengthTail = lengthTailFromPrevLeg { // check if we are at the start of the leg
                stepStart = route[currentLegIndex] // start of the leg
                if leg.contains(point: leg.point(atDistance: lengthTail)) { // check if the current leg contains the step which does not fitted into the prev one
                    stepEnd = leg.point(atDistance: lengthTail)
                    currentLeg.steps.append(Step(point: stepStart)) // add the step to the current leg
                    legs.append(currentLeg) // add the current leg to the legs list
                    currentLeg = Leg(steps: [])
                    if stepEnd == route[currentLegIndex + 1] { // check if our step is the leg end
                        offsetInLeg = 0.0 // move to the new leg
                        currentLegIndex += 1
                    } else {
                        offsetInLeg = lengthTail // remain in the current one
                    }
                    lengthTailFromPrevLeg = nil
                } else { // it is not the current leg step
                    stepEnd = route[currentLegIndex + 1]
                    let step = Step(point: stepStart)
                    currentLeg.steps.append(step)
                    currentLegIndex += 1 // switch to the new leg
                    offsetInLeg = 0.0 // clear the offset from start
                    lengthTailFromPrevLeg = lengthTail
                }
                continue // continue collection of the steps for the current or the new leg
            }
            //we are in the old leg and add the itermeditary steps below until we reach the leg end
            stepStart = leg.point(atDistance: offsetInLeg)
            if leg.contains(point: leg.point(atDistance: offsetInLeg + CGFloat(5.0))) { // check if the 5m away from start step is still in the leg
                stepEnd = leg.point(atDistance: offsetInLeg + CGFloat(5.0))
                currentLeg.steps.append(Step(point: stepStart)) // add the step to current leg
                legs.append(currentLeg) // add the leg to the leg list
                currentLeg = Leg(steps: [])
                if stepEnd == route[currentLegIndex + 1] { // check wherether we reached the end on the leg
                    offsetInLeg = 0.0 // new leg
                    currentLegIndex += 1
                } else {
                    offsetInLeg = offsetInLeg + CGFloat(5.0) // old leg
                }
                lengthTailFromPrevLeg = nil
            } else { // the step is not in the leg
                if stepStart ~= route[currentLegIndex + 1] { // check if start is not the end now
                    break
                }
                stepEnd = route[currentLegIndex + 1] // we have reached the end of the leg
                let step = Step(point: stepStart) // final point
                currentLeg.steps.append(step) // add the final point to the current leg
                currentLegIndex += 1 // switch to the new leg
                offsetInLeg = 0.0 // move the new leg start
                lengthTailFromPrevLeg = CGFloat(5.0)
            }
        }
        if currentLeg.steps.count > 0 { // add the final leg to the list if it is not empty
            legs.append(currentLeg)
        }
        return legs
    }
    
    func setNavigation(forRoute route: [CGPoint]) -> [SCNNode] {
        let routeLegs = getLegs(route: route)
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
    
    func setExtraNodes(nodes: [CGPoint], objects : [ARNode]) -> [SCNNode]{
        var scnNodes: [SCNNode] = []
        for index in 0..<objects.count {
            let node : ARNode = ARNode()
            let arNode = SCNNode(geometry: node.createInvisibleNode())
            let position = setPosition(point: nodes[index])
            arNode.runAction(SCNAction.repeat(SCNAction.sequence([position]), count: 1))
            
            let imageNode = node.makeBillboardNode(objects[index].image)
            imageNode.position = SCNVector3Make(0, 4, 0)
            arNode.addChildNode(imageNode)
            
            let textNode = node.makeBillboardNode(objects[index].title.image()!)
            textNode.position = SCNVector3Make(0, 10, 0)
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
