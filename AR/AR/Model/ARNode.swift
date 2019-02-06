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



class ARNode: SCNNode {
    var location: CLLocation! // postion in real world
    var distance: Double! // distance of the step
    var title: String! // title of the step
    
    init(radius: CGFloat = 0.2, color: UIColor = UIColor.blue, transparency: CGFloat = 0.3, height: CGFloat = 0.01) {
        let cylinder = SCNCylinder(radius: radius, height: height)
        cylinder.firstMaterial?.diffuse.contents = color
        cylinder.firstMaterial?.transparency = transparency
        cylinder.firstMaterial?.lightingModel = .constant
        super.init()
        self.geometry = cylinder
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
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createNode(with radius: CGFloat, color: UIColor) -> SCNGeometry {
        let material = SCNMaterial()
        material.diffuse.contents = color
        material.lightingModel = .constant
        return ARSCNArrowGeometry(material: material)
    }
    
    func addNodeWithText(with radius: CGFloat, and color: UIColor, and text: String) {
        let node = SCNNode(geometry: createNode(with: radius, color: color))
        let newText = SCNText(string: title, extrusionDepth: 0.05)
        newText.font = UIFont (name: "AvenirNext-Medium", size: 1)
        newText.firstMaterial?.diffuse.contents = UIColor.white
        let _textNode = SCNNode(geometry: newText)
        let annotationNode = SCNNode()
        annotationNode.addChildNode(_textNode)
        annotationNode.position = node.position
        addChildNode(node)
        addChildNode(annotationNode)
    }
    
    func addNode(with radius: CGFloat, and color: UIColor) {
        let node = SCNNode(geometry: createNode(with: radius, color: color))
        addChildNode(node)
    }
}

class ARSCNArrowGeometry: SCNGeometry {
    convenience init(material: SCNMaterial) {
        let vertices: [SCNVector3] = [
            SCNVector3Make(-0.02,  0.00,  0.00), // 0
            SCNVector3Make(-0.02,  0.50, -0.33), // 1
            SCNVector3Make(-0.10,  0.44, -0.50), // 2
            SCNVector3Make(-0.22,  0.00, -0.39), // 3
            SCNVector3Make(-0.10, -0.44, -0.50), // 4
            SCNVector3Make(-0.02, -0.50, -0.33), // 5
            SCNVector3Make( 0.02,  0.00,  0.00), // 6
            SCNVector3Make( 0.02,  0.50, -0.33), // 7
            SCNVector3Make( 0.10,  0.44, -0.50), // 8
            SCNVector3Make( 0.22,  0.00, -0.39), // 9
            SCNVector3Make( 0.10, -0.44, -0.50), // 10
            SCNVector3Make( 0.02, -0.50, -0.33), // 11
        ]
        let sources: [SCNGeometrySource] = [SCNGeometrySource(vertices: vertices)]
        let indices: [Int32] = [0,3,5, 3,4,5, 1,2,3, 0,1,3, 10,9,11, 6,11,9, 6,9,7, 9,8,7,
                                6,5,11, 6,0,5, 6,1,0, 6,7,1, 11,5,4, 11,4,10, 9,4,3, 9,10,4, 9,3,2, 9,2,8, 8,2,1, 8,1,7]
        let geometryElements = [SCNGeometryElement(indices: indices, primitiveType: .triangles)]
        self.init(sources: sources, elements: geometryElements)
        self.materials = [material]
    }
}
