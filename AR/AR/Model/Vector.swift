//
//  Vector.swift
//  AR
//
//  Created by Анастасия on 30/01/2019.
//  Copyright © 2019 Anastasia. All rights reserved.
//

import Foundation
import CoreLocation
import SceneKit

struct Vector : Hashable {
    public var x: Scalar
    public var y: Scalar
    public static let x = Vector(1, 0)
    
    public var hashValue: Int {
        return x.hashValue &+ y.hashValue
    }
    
    public init(_ v: CGPoint) {
        self.init(Scalar(v.x), Scalar(v.y))
    }
    
    public init(_ x: Scalar, _ y: Scalar) {
        self.x = x;
        self.y = y;
    }
    
    public func toCGPoint() -> CGPoint {
        return CGPoint(self)
    }
    
    public var lengthSquared: Scalar {
        return x * x + y * y
    }
    
    public var length: Scalar {
        return sqrt(lengthSquared)
    }    
   
    public func dot(_ v: Vector) -> Scalar {
        return x * v.x + y * v.y
    }
    
    public func cross(_ v: Vector) -> Scalar {
        return x * v.y - y * v.x
    }
    
    public func normalized() -> Vector {
        let lengthSquared = self.lengthSquared
        if lengthSquared ~= 0 || lengthSquared ~= 1 {
            return self
        }
        return self / sqrt(lengthSquared)
    }
    
    public func angle(with v: Vector) -> Scalar {
        if self == v {
            return 0
        }
        let t1 = normalized()
        let t2 = v.normalized()
        let cross = t1.cross(t2)
        let dot = max(-1, min(1, t1.dot(t2)))
        return atan2(cross, dot)
    }
    
    public static func +(lhs: Vector, rhs: Vector) -> Vector {
        return Vector(lhs.x + rhs.x, lhs.y + rhs.y)
    }
    
    public static func -(lhs: Vector, rhs: Vector) -> Vector {
        return Vector(lhs.x - rhs.x, lhs.y - rhs.y)
    }
    
    public static func *(lhs: Vector, rhs: Vector) -> Vector {
        return Vector(lhs.x * rhs.x, lhs.y * rhs.y)
    }
    
    public static func *(lhs: Vector, rhs: Scalar) -> Vector {
        return Vector(lhs.x * rhs, lhs.y * rhs)
    }
    
    public static func /(lhs: Vector, rhs: Scalar) -> Vector {
        return Vector(lhs.x / rhs, lhs.y / rhs)
    }
}
