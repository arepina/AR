//
//  CGPoint+Extension.swift
//  AR
//
//  Created by Анастасия on 30/01/2019.
//  Copyright © 2019 Anastasia. All rights reserved.
//

import Foundation
import CoreLocation
import SceneKit

extension CGPoint : Hashable{    
    
    var positionInAR: SCNVector3 {
        return SCNVector3(y, 0.0, x)
    }
    
    public var hashValue:Int {
        return self.x.hashValue ^ self.y.hashValue
    }
    
    init(position: SCNVector3) {
        self.init(x: CGFloat(position.z), y: CGFloat(position.x))
    }
    
    init(_ v: Vector) {
        self.init(x: CGFloat(v.x), y: CGFloat(v.y))
    }
    
    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow(self.x - point.x, 2) + pow(self.y - point.y, 2))
    }
}
