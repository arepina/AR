//
//  Array+Extension.swift
//  AR
//
//  Created by Анастасия on 30/01/2019.
//  Copyright © 2019 Anastasia. All rights reserved.
//

import Foundation

extension Array {
    public func skip(_ n: Int) -> Array {
        let result: [Element] = []
        return n > count ? result : Array(self[Int(n)..<count])
    }
}
