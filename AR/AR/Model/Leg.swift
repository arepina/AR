//
//  Animation.swift
//  AR
//
//  Created by Анастасия on 30/01/2019.
//  Copyright © 2019 Anastasia. All rights reserved.
//

import Foundation
import SceneKit

struct Leg {
    var steps: [Step]
    var points: [CGPoint] {
        return steps.map { [$0.point] }.flatMap { $0 }
    }
}
