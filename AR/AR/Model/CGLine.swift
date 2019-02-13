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
    let MT_EPS: CGFloat = 1e-4
    
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
    
    func intersection(withRect rect: CGRect) -> CGPoint? {
        let top = CGLine(point1: rect.topLeft, point2: rect.topRight)
        let right = CGLine(point1: rect.topRight, point2: rect.bottomRight)
        let bottom = CGLine(point1: rect.bottomLeft, point2: rect.bottomRight)
        let left = CGLine(point1: rect.topLeft, point2: rect.bottomLeft)
        
        
        let points: [CGPoint?] = [ top.intersection(withLine: self),
                                   right.intersection(withLine: self),
                                   left.intersection(withLine: self),
                                   bottom.intersection(withLine: self)]
        
        for p in points {
            if p != nil {
                return p!
            }
        }
        
        return nil;
    }
    
    func intersection(withLine line: CGLine) -> CGPoint? {
        let line1 = self
        let line2 = line
        
        let x1 = line1.point1.x
        let y1 = line1.point1.y
        let x2 = line1.point2.x
        let y2 = line1.point2.y
        let x3 = line2.point1.x
        let y3 = line2.point1.y
        let x4 = line2.point2.x
        let y4 = line2.point2.y
        
        let denom  = (y4-y3) * (x2-x1) - (x4-x3) * (y2-y1)
        let numera = (x4-x3) * (y1-y3) - (y4-y3) * (x1-x3)
        let numerb = (x2-x1) * (y1-y3) - (y2-y1) * (x1-x3)
        
        /* Are the lines coincident? */
        if (abs(numera) < MT_EPS && abs(numerb) < MT_EPS && abs(denom) < MT_EPS) {
            return CGPoint(x: (x1 + x2) / 2.0, y: (y1 + y2) / 2.0)
        }
        
        /* Are the line parallel */
        if (abs(denom) < MT_EPS) {
            return nil
        }
        
        /* Is the intersection along the the segments */
        let mua = numera / denom
        let mub = numerb / denom
        if (mua < 0 || mua > 1 || mub < 0 || mub > 1) {
            return nil
        }
        return CGPoint(x: x1 + mua * (x2 - x1), y: y1 + mua * (y2 - y1))
    }
}
