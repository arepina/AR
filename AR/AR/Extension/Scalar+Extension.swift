//
//  Scalar+Extension.swift
//  AR
//
//  Created by Анастасия on 01/02/2019.
//  Copyright © 2019 Anastasia. All rights reserved.
//

import Foundation

public typealias Scalar = Float

extension Scalar {
    public static let halfPi = pi / 2
    public static let quarterPi = pi / 4
    public static let twoPi = pi * 2
    public static let degreesPerRadian = 180 / pi
    public static let radiansPerDegree = pi / 180
    public static let epsilon: Scalar = 0.0001
    
    public static func ~=(lhs: Scalar, rhs: Scalar) -> Bool {
        return Swift.abs(lhs - rhs) < .epsilon
    }
    
    fileprivate var sign: Scalar {
        return self > 0 ? 1 : -1
    }
}
