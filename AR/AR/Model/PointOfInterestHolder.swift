//
//  PointOfInterestHolder.swift
//  AR
//
//  Created by Анастасия on 08/02/2019.
//  Copyright © 2019 Anastasia. All rights reserved.
//

import Foundation

class PointOfInterestHolder{    
    var annotationInstructions : [PointOfInterest] = [] // instructions for main steps
    var annotationMuseums : [PointOfInterest] = [] //  museums pins
    var annotationTheaters : [PointOfInterest] = [] //  theaters pins
    
    init(){
        annotationInstructions = [] 
        annotationMuseums = []
        annotationTheaters = []
    }
}
