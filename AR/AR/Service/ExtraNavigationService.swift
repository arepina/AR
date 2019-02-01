//
//  Extra.swift
//  AR
//
//  Created by Анастасия on 30/01/2019.
//  Copyright © 2019 Anastasia. All rights reserved.
//

import Foundation
import CoreLocation
import SceneKit
import MapKit

class ExtraNavigationService{
    static func convert(scnView: SCNView, navService: NavigationService, coordinate: CLLocationCoordinate2D) -> SCNVector3? {
        let location = CLLocation.bestLocationEstimate(locations: navService.getLocations())
        let translation = location.coordinate.coordinatesTranslation(toCoordinate: coordinate)
        return SCNVector3(
            x: scnView.pointOfView!.worldPosition.x + Float(translation.coordinate.longitude),
            y: 0.0,
            z: scnView.pointOfView!.worldPosition.z - Float(translation.coordinate.latitude)
        )
    }
    
    static func divideRoute(route: [CGPoint], toAnimationsOfLength animationLength: Float) -> [Animation] {
        guard route.count >= 2 else { return [] }
        var animations: [Animation] = []
        var currentAnimation: Animation = Animation(steps: [])
        let segmentsCount = Array(zip(route, route.skip(1))).count
        var currentSegmentIndex = 0
        var offsetInSegment: CGFloat = 0.0
        var lengthTailFromPrevSegment: CGFloat? = nil
        while currentSegmentIndex < segmentsCount {
            let segmentStart = route[currentSegmentIndex]
            let segmentEnd = route[currentSegmentIndex + 1]
            let segmentLine = CGLine(point1: segmentStart, point2: segmentEnd)
            var stepStart: CGPoint
            var stepEnd: CGPoint            
            if let lengthTail = lengthTailFromPrevSegment {
                assert(offsetInSegment == 0.0)
                stepStart = segmentStart
                let stepEndCandidate = segmentLine.point(atDistance: lengthTail)
                if segmentLine.contains(point: stepEndCandidate) {
                    stepEnd = stepEndCandidate
                    currentAnimation.steps.append(Step(start: stepStart, end: stepEnd))
                    animations.append(currentAnimation)
                    currentAnimation = Animation(steps: [])
                    if stepEnd == segmentEnd {
                        offsetInSegment = 0.0
                        currentSegmentIndex += 1
                    } else {
                        offsetInSegment = lengthTail
                    }
                    lengthTailFromPrevSegment = nil
                } else {
                    stepEnd = segmentEnd
                    let step = Step(start: stepStart, end: stepEnd)
                    currentAnimation.steps.append(step)
                    currentSegmentIndex += 1
                    offsetInSegment = 0.0
                    lengthTailFromPrevSegment = lengthTail - step.length
                }
                continue
            }
            stepStart = segmentLine.point(atDistance: offsetInSegment)
            assert(segmentLine.contains(point: stepStart))
            let nextOffset = offsetInSegment + CGFloat(animationLength)
            let stepEndCandidate = segmentLine.point(atDistance: nextOffset)
            if segmentLine.contains(point: stepEndCandidate) {
                stepEnd = stepEndCandidate
                currentAnimation.steps.append(Step(start: stepStart, end: stepEnd))
                animations.append(currentAnimation)
                currentAnimation = Animation(steps: [])
                if stepEnd == segmentEnd {
                    offsetInSegment = 0.0
                    currentSegmentIndex += 1
                } else {
                    offsetInSegment = nextOffset
                }
                lengthTailFromPrevSegment = nil
            } else {
                if stepStart ~= segmentEnd {
                    break
                }
                stepEnd = segmentEnd
                let step = Step(start: stepStart, end: stepEnd)
                currentAnimation.steps.append(step)
                currentSegmentIndex += 1
                offsetInSegment = 0.0
                lengthTailFromPrevSegment = CGFloat(animationLength) - step.length
            }
        }
        if currentAnimation.steps.count > 0 {
            animations.append(currentAnimation)
        }
        return animations
    }
    
    static func createPolyline(forRoute route: [CGPoint], withAnimationLength animationLength: Float, animationDuration: TimeInterval = 2.0) -> [SCNNode] {
        let animations = divideRoute(route: route, toAnimationsOfLength: animationLength)
        let nodesCount = animations.count
        var nodes: [SCNNode] = []
        for index in 0..<nodesCount {
            let animation = animations[index]
            let stepsLength = animation.steps.map { $0.length }.reduce(0, +)
            let arrow = SCNNode(geometry: ARNode.arrow())
            guard let firstStep = animation.steps.first else { continue }
            let reset = createResetAction(firstStep: firstStep)
            var stepActions: [SCNAction] = []
            for stepIndex in 0..<animation.steps.count {
                let step = animation.steps[stepIndex]
                let prevStep = stepIndex - 1 >= 0 ? animation.steps[stepIndex - 1] : nil
                let stepAction = createAction(forStep: step, previousStep: prevStep,
                                              animationLength: stepsLength, animationDuration: animationDuration)
                stepActions.append(stepAction)
            }
            arrow.runAction(SCNAction.repeatForever(SCNAction.sequence([reset] + stepActions)))
            nodes.append(arrow)
        }
        return nodes
    }
    
    static func createAction(forStep step: Step, previousStep: Step?, animationLength: CGFloat,
                      animationDuration: TimeInterval) -> SCNAction
    {
        let stepDuration = (step.length / animationLength) * CGFloat(animationDuration)
        let moveBy = CGPoint(step.vec).positionInAR
        let move = SCNAction.move(by: moveBy, duration: TimeInterval(stepDuration))
        if let prevStep = previousStep {
            let rotationAngle = prevStep.vec.angle(with: step.vec)
            let rotate = SCNAction.rotateBy(x: 0, y: CGFloat(rotationAngle), z: 0, duration: 0)
            return SCNAction.sequence([rotate, move])
        } else {
            return move
        }
    }
    
    static func createResetAction(firstStep: Step) -> SCNAction {
        let initialPosition = firstStep.start.positionInAR
        let initialAngle = Vector.x.angle(with: firstStep.vec) // Стрелка направлена по оси Z, которая переводится в 2D (CGPoint) как к-та X
        let moveToInitial = SCNAction.move(to: initialPosition, duration: 0.0)
        let rotateToInitial = SCNAction.rotateTo(x: 0.0, y: CGFloat(initialAngle), z: 0.0, duration: 0.0)
        let reset = SCNAction.group([moveToInitial, rotateToInitial])
        return reset
    }
}
