//
//  FloatingPoint+Extension.swift
//  AR
//
//  Created by Анастасия on 03/12/2018.
//  Copyright © 2018 Anastasia. All rights reserved.
//

import Foundation

//For the matrix transformation, we will use radians instead of degrees as angle units
extension FloatingPoint {
    func toRadians() -> Self {
        return self * .pi / 180
    }
    
    func toDegrees() -> Self {
        return self * 180 / .pi
    }
}
