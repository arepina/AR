//
//  LegsService.swift
//  AR
//
//  Created by Анастасия on 26/04/2019.
//  Copyright © 2019 Anastasia. All rights reserved.
//

import Foundation
import CoreLocation
import SceneKit
import MapKit

class LegsService{
    var legs: [Leg] = []
    var currentLeg: Leg = Leg(steps: [])
    var currentLegIndex = 0
    var offsetInLeg: CGFloat = 0.0
    var lengthTailFromPrevLeg: CGFloat? = nil
    var stepStart: CGPoint = CGPoint()
    var stepEnd: CGPoint = CGPoint()
    
    func getLegs(route: [CGPoint]) -> [Leg] {
        guard route.count >= 2 else { return [] }
        let legsCount = Array(zip(route, route.skip(1))).count
        while currentLegIndex < legsCount { // iterate all the route legs
            let leg = CGLine(point1: route[currentLegIndex], point2: route[currentLegIndex + 1])
            if let lengthTail = lengthTailFromPrevLeg { // check if we are at the start of the leg
                stepStart = route[currentLegIndex] // start of the leg
                if leg.contains(point: leg.point(atDistance: lengthTail)) {
                    // current leg contains the step which does not fitted into prev one
                    containNotFittedSteps(route: route, lengthTail: lengthTail, leg: leg)
                } else { // it is not the prev leg step -> create a new leg
                    doNotContainNotFittedSteps(route: route, lengthTail: lengthTail)
                }
                continue // continue collection of the steps for the current or the new leg
            }
            //we are in the old leg and add the itermeditary steps below until we reach the leg end
            stepStart = leg.point(atDistance: offsetInLeg)
            if leg.contains(point: leg.point(atDistance: offsetInLeg + CGFloat(5.0))) {
                // check if the 5m away from start step is still in the leg
                stillInLeg(route: route, leg: leg)
            } else { // the step is not in the leg
                if stepStart ~= route[currentLegIndex + 1] { // check if start is not the end now
                    break
                }
                notStillInLeg(route: route)
            }
        }
        if currentLeg.steps.count > 0 { // add the final leg to the list if it is not empty
            legs.append(currentLeg)
        }
        return legs
    }
    
    func notStillInLeg(route: [CGPoint]){
        stepEnd = route[currentLegIndex + 1] // we have reached the end of the leg
        let step = Step(point: stepStart) // final point
        currentLeg.steps.append(step) // add the final point to the current leg
        currentLegIndex += 1 // switch to the new leg
        offsetInLeg = 0.0 // move the new leg start
        lengthTailFromPrevLeg = CGFloat(5.0)
    }
    
    func stillInLeg(route: [CGPoint], leg: CGLine){
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
    }
    
    func containNotFittedSteps(route: [CGPoint], lengthTail: CGFloat, leg: CGLine){
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
    }
    
    func doNotContainNotFittedSteps(route: [CGPoint], lengthTail: CGFloat){
        stepEnd = route[currentLegIndex + 1]
        let step = Step(point: stepStart)
        currentLeg.steps.append(step)
        currentLegIndex += 1 // switch to the new leg
        offsetInLeg = 0.0 // clear the offset from start
        lengthTailFromPrevLeg = lengthTail
    }
}
