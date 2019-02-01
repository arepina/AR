//
//  Step.swift
//  AR
//
//  Created by Анастасия on 30/01/2019.
//  Copyright © 2019 Anastasia. All rights reserved.
//

import Foundation
import SceneKit

struct Step {
    let start: CGPoint
    let end: CGPoint
    let length: CGFloat
    
    init(start: CGPoint, end: CGPoint) {
        assert(start != end)
        self.start = start
        self.end = end
        self.length = start.distance(to: end)
    }
    
    var vec: Vector {
        return Vector(end) - Vector(start)
    }
}
