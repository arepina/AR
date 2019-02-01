//
//  Matrix.swift
//  AR
//
//  Created by Анастасия on 03/12/2018.
//  Copyright © 2018 Anastasia. All rights reserved.
//

import UIKit
import CoreLocation
import SceneKit

class Matrix{
    
    //Transform = Scaling * Rotation * Translation
    static func transformMatrix(for matrix: simd_float4x4, originLocation: CLLocation, location: CLLocation) -> simd_float4x4 {
        let bearing = bearingBetweenLocations(originLocation, location)
        let position = vector_float4(0.0, 0.0, -Float(location.distance(from: originLocation)), 0.0)
        let translationMatrix = Matrix.translationMatrix(matrix_identity_float4x4, position)
        let rotationMatrix = Matrix.rotateAroundY(matrix_identity_float4x4, Float(bearing))
        let transformMatrix = simd_mul(rotationMatrix, translationMatrix)
        return simd_mul(matrix, transformMatrix)
    }
    
    
    //    column 0  column 1  column 2  column 3
    //         1        0         0       X          x        x + X*w 
    //         0        1         0       Y      x   y    =   y + Y*w 
    //         0        0         1       Z          z        z + Z*w 
    //         0        0         0       1          w           w    
    static func translationMatrix(_ matrix: simd_float4x4, _ translation : vector_float4) -> simd_float4x4 {
        var matrix = matrix
        matrix.columns.3 = translation
        return matrix
    }
    
    //    column 0  column 1  column 2  column 3
    //        cosθ      0       sinθ      0    
    //         0        1         0       0    
    //       −sinθ      0       cosθ      0    
    //         0        0         0       1    
    static func rotateAroundY(_ matrix: simd_float4x4, _ degrees: Float) -> simd_float4x4 {
        var matrix = matrix
        matrix.columns.0.x = cos(degrees)
        matrix.columns.0.z = -sin(degrees)
        matrix.columns.2.x = sin(degrees)
        matrix.columns.2.z = cos(degrees)
        return matrix.inverse
    }
    
    //    column 0  column 1  column 2  column 3
    //         1        0         0       X    
    //         0        1         0       Y    
    //         0        0         1       Z    
    //         0        0         0       1    
    static func positionFromTransform(_ transform: matrix_float4x4) -> SCNVector3 {
        return SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
    }
    
    //Bearing (the angle) between two coordinates. Finding the bearing set us up to create a rotation transformation to orient our node in the proper direction
    static func bearingBetweenLocations(_ originLocation: CLLocation, _ driverLocation: CLLocation) -> Double {
        let lat1 = originLocation.coordinate.latitude.toRadians()
        let lon1 = originLocation.coordinate.longitude.toRadians()
        let lat2 = driverLocation.coordinate.latitude.toRadians()
        let lon2 = driverLocation.coordinate.longitude.toRadians()
        let longitudeDiff = lon2 - lon1
        let y = sin(longitudeDiff) * cos(lat2);
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(longitudeDiff)
        return atan2(y, x)
    }
}
