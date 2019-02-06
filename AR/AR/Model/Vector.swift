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
    public static let zero = Vector(0, 0)
    public static let x = Vector(1, 0)
    public static let y = Vector(0, 1)
    
    public init(_ v: CGPoint) {
        self.init(Scalar(v.x), Scalar(v.y))
    }
    
    public init(_ v: CGSize) {
        self.init(Scalar(v.width), Scalar(v.height))
    }
    
    public init(_ v: CGVector) {
        self.init(Scalar(v.dx), Scalar(v.dy))
    }
    
    public init(_ x: Scalar, _ y: Scalar) {
        self.x = x
        self.y = y
    }
    
    public init(_ v: [Scalar]) {
        assert(v.count == 2, "array must contain 2 elements, contained \(v.count)")
        self.init(v[0], v[1])
    }
    
    public func toCGPoint() -> CGPoint {
        return CGPoint(self)
    }
    
    public var hashValue: Int {
        return x.hashValue &+ y.hashValue
    }
    
    public var lengthSquared: Scalar {
        return x * x + y * y
    }
    
    public var length: Scalar {
        return sqrt(lengthSquared)
    }
    
    public var inverse: Vector {
        return -self
    }
    
    public func toArray() -> [Scalar] {
        return [x, y]
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
    
    public func rotated(by radians: Scalar) -> Vector {
        let cs = cos(radians)
        let sn = sin(radians)
        return Vector(x * cs - y * sn, x * sn + y * cs)
    }
    
    public func rotated(by radians: Scalar, around pivot: Vector) -> Vector {
        return (self - pivot).rotated(by: radians) + pivot
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
    
    public func interpolated(with v: Vector, by t: Scalar) -> Vector {
        return self + (v - self) * t
    }
    
    public static prefix func -(v: Vector) -> Vector {
        return Vector(-v.x, -v.y)
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
    
//    public static func *(lhs: Vector, rhs: Matrix3) -> Vector {
//        return Vector(
//            lhs.x * rhs.m11 + lhs.y * rhs.m21 + rhs.m31,
//            lhs.x * rhs.m12 + lhs.y * rhs.m22 + rhs.m32
//        )
//    }
    
    public static func /(lhs: Vector, rhs: Vector) -> Vector {
        return Vector(lhs.x / rhs.x, lhs.y / rhs.y)
    }
    
    public static func /(lhs: Vector, rhs: Scalar) -> Vector {
        return Vector(lhs.x / rhs, lhs.y / rhs)
    }
    
    public static func ==(lhs: Vector, rhs: Vector) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
    
    public static func ~=(lhs: Vector, rhs: Vector) -> Bool {
        return lhs.x ~= rhs.x && lhs.y ~= rhs.y
    }
}
