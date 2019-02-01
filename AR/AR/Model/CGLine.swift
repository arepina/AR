//
//  CGLine.swift
//  AR
//
//  Created by Анастасия on 30/01/2019.
//  Copyright © 2019 Anastasia. All rights reserved.
//

import Foundation
import SceneKit

//Used in route by parts division
struct CGLine {
    let point1: CGPoint
    let point2: CGPoint
    
    func point(atDistance distance: CGFloat) -> CGPoint {
        let start = Vector(self.point1)
        let end = Vector(self.point2)
        let vec = start + (end - start).normalized() * Scalar(distance)
        return CGPoint(vec)
    }
    
    func contains(point: CGPoint) -> Bool {
        let end: CGPoint = self.point2
        let start: CGPoint = self.point1
        let startToEnd = Vector(end) - Vector(start)
        let startToPoint = Vector(point) - Vector(start)
        let pointToEnd = Vector(end) - Vector(point)
        if abs(CGFloat(startToPoint.length)) < 1e-4 || abs(CGFloat(pointToEnd.length)) < 1e-4 {
            return true
        } else {
            return (startToPoint.angle(with: startToEnd).truncatingRemainder(dividingBy: .twoPi) ~= 0.0)
                && (startToPoint.length <= startToEnd.length)
        }
    }
}
