//
//  ARNode.swift
//  AR
//
//  Created by Анастасия on 01/12/2018.
//  Copyright © 2018 Anastasia. All rights reserved.
//

import UIKit
import ARKit
import CoreLocation
import ARCL

class ARNode: SCNNode {
    var location: CLLocation! // postion in real world
    var distance: Double! // distance of the step
    var title: String! // title of the step
    var image: UIImage! // image
    var annotationNode : LocationAnnotationNode!
    
    override init() {
        super.init()
    }
    
    init(location: CLLocation, title: String, distance: Double) {
        super.init()
        self.location = location
        self.title = title
        self.distance = distance
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = SCNBillboardAxis.Y
        constraints = [billboardConstraint]
    }
    
    init(location : CLLocation, title : String, image : UIImage) {
        super.init()
        self.location = location
        self.title = title
        self.image = image
    }
    
    func makeBillboardNode(_ image: UIImage) -> SCNNode {
        let plane = SCNPlane(width: 10, height: 10)
        plane.firstMaterial!.diffuse.contents = image
        let node = SCNNode(geometry: plane)
        node.constraints = [SCNBillboardConstraint()]
        return node
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createNode() -> SCNGeometry {
        let c : SCNCapsule = SCNCapsule(capRadius: 0.5, height: 2.0)
        c.firstMaterial?.lightingModel = .constant
        c.firstMaterial?.diffuse.contents = UIColor.blue
        return c
    }
    
    func createTextNode() -> SCNGeometry{
        let newText = SCNText(string: title, extrusionDepth: 0.05)
        newText.font = UIFont (name: "AvenirNext-Medium", size: 1)
        newText.firstMaterial?.diffuse.contents = UIColor.white
        return newText
    }
}
