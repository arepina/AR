//
//  Object.swift
//  AR
//
//  Created by Анастасия on 07/12/2018.
//  Copyright © 2018 Anastasia. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit
import ARCL
import ARKit

class Object{
    var location : CLLocation!
    var image : UIImage!
    var title : String
    var annotationNode : LocationAnnotationNode!
    
    init(l : CLLocation, t : String, i : UIImage) {
        location = l
        title = t
        image = i
        annotationNode = LocationAnnotationNode(location: location, image: image)
        let label = makeBillboardNode(title.image()!)
        // Position it on top of the annotationNode
        label.position = SCNVector3Make(0, 4, 0)
        // Add it as a child of the annotationNode
        annotationNode.addChildNode(label)
    }
    
    func makeBillboardNode(_ image: UIImage) -> SCNNode {
        let plane = SCNPlane(width: 10, height: 10)
        plane.firstMaterial!.diffuse.contents = image
        let node = SCNNode(geometry: plane)
        node.constraints = [SCNBillboardConstraint()]
        return node
    }
}
