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
    
//    func calculateLeg(for index: Int, and tripStep: MKRoute.Step, and steps : [MKRoute.Step] ) -> [CLLocationCoordinate2D] {
//        var previousLocation : CLLocation
//        if(index == 0) // intermediary coordinates for first route step
//        {
//            previousLocation = CLLocation(latitude: SwiftLocation.Locator.currentLocation!.coordinate.latitude, longitude: SwiftLocation.Locator.currentLocation!.coordinate.longitude)
//        }else{ // intermediary coordinates for route step that is not first
//            previousLocation = CLLocation(latitude: steps[index - 1].polyline.coordinate.latitude, longitude: steps[index - 1].polyline.coordinate.longitude)
//        }
//        let nextLocation = CLLocation(latitude: tripStep.polyline.coordinate.latitude, longitude: tripStep.polyline.coordinate.longitude)
//        let leg = CLLocationCoordinate2D.getIntermediaryLocations(currentLocation: previousLocation, destinationLocation: nextLocation)
//        return leg
//    }
//    
//    func addNodes(legs: [[CLLocationCoordinate2D]], steps: [MKRoute.Step], sceneView: SceneLocationView!) -> [ARNode]{
//        var nodes : [ARNode] = []
//        for step in steps { // the main points
//            let locationTransform = Matrix.transformMatrix(for: matrix_identity_float4x4, originLocation: SwiftLocation.Locator.currentLocation!, location: step.getLocation())
//            let position = SCNVector3Make(locationTransform.columns.3.x, locationTransform.columns.3.y, locationTransform.columns.3.z)
//            let distance = step.getLocation().distance(from: SwiftLocation.Locator.currentLocation!)
//            let scale = 100 / Float(distance)
//            let stepAnchor = ARAnchor(transform: locationTransform)
//            let sphere = ARNode(location: step.getLocation(), anchor: stepAnchor, title: step.instructions, distance: distance)
//            sphere.scale = SCNVector3(x: scale, y: scale, z: scale)
//            sphere.position = position
//            sphere.addNodeMain(with: 0.3, and: .green, and: step.instructions)
//            nodes.append(sphere)
//            sceneView.session.add(anchor: stepAnchor)
//            sceneView.scene.rootNode.addChildNode(sphere)
//        }
//        let coordinates = legs.flatMap { $0 } // all the legs together
//        let intermediaryLocations = coordinates.map { CLLocation(latitude: $0.latitude, longitude: $0.longitude) } // all the intermediary locations in the legs together
//        for location in intermediaryLocations{
//            let locationTransform = Matrix.transformMatrix(for: matrix_identity_float4x4, originLocation: SwiftLocation.Locator.currentLocation!, location: location)
//            let distance = location.distance(from: SwiftLocation.Locator.currentLocation!)
//            let scale = 100 / Float(distance)
//            let position = SCNVector3Make(locationTransform.columns.3.x, locationTransform.columns.3.y, locationTransform.columns.3.z)
//            let stepAnchor = ARAnchor(transform: locationTransform)
//            let sphere = ARNode(location: location, anchor: stepAnchor, title: "", distance: distance)
//            sphere.scale = SCNVector3(x: scale, y: scale, z: scale)
//            sphere.position = position
//            sphere.addNodeIntermeditary(with: 0.25, and: .red)
//            nodes.append(sphere)
//            sceneView.session.add(anchor: stepAnchor)
//            sceneView.scene.rootNode.addChildNode(sphere)
//        }
//        return nodes
//    }
//    
//    func updateNodes(nodes: [ARNode]) {
//        //when user is moving, the nodes postion may change, so update them
//            SCNTransaction.begin()
//            SCNTransaction.animationDuration = 0.5
//            if updatedLocations.count > 0 {
//                let startLocation = bestLocationEstimate(locations: updatedLocations) // choose the best out of stores
//                for node in nodes {
//                    let translation = Matrix.transformMatrix(for: matrix_identity_float4x4, originLocation: startLocation, location: node.location)
//                    let position = SCNVector3Make(translation.columns.3.x, translation.columns.3.y, translation.columns.3.z)
//                    let distance = node.location.distance(from: startLocation)
//                    DispatchQueue.main.async {
//                        let scale = 100 / Float(distance)
//                        node.scale = SCNVector3(x: scale, y: scale, z: scale)
//                        node.anchor = ARAnchor(transform: translation)
//                        node.position = position
//                    }
//                }
//            }
//            SCNTransaction.commit()
//    }
    
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
            let node : ARNode = ARNode()
            let arNode = SCNNode(geometry: node.createNode(with: 0.3, color: .red))
            let position = setPosition(firstStep: leg.steps.first!)
            arNode.runAction(SCNAction.repeat(SCNAction.sequence([position]), count: 1))
            nodes.append(arNode)
        }
        return nodes
    }
    
    func setPosition(firstStep: Step) -> SCNAction {
        let initialPosition = firstStep.point.positionInAR
        let initialAngle = Vector.x.angle(with: Vector(0,0))
        let move = SCNAction.move(to: initialPosition, duration: 0.0)
        let rotate = SCNAction.rotateTo(x: 0.0, y: CGFloat(initialAngle), z: 0.0, duration: 0.0)
        let reset = SCNAction.group([move, rotate])
        return reset
    }
}
