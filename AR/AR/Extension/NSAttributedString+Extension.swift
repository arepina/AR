//
//  NSAttributedString.swift
//  AR
//
//  Created by Анастасия on 13/02/2019.
//  Copyright © 2019 Anastasia. All rights reserved.
//

import Foundation
import UIKit
import SceneKit

public extension NSAttributedString {
    
    func boundingRect(size: CGSize) -> CGRect {
        let rect = self.boundingRect(with: size, options: .usesLineFragmentOrigin, context: nil)
        return rect.integral
    }
    
    func boundingRect(width: CGFloat) -> CGRect {
        return boundingRect(size: CGSize(width: width, height: .infinity))
    }
    
    func boundingSize(width: CGFloat) -> CGSize {
        return boundingRect(width: width).size
    }
    
}
