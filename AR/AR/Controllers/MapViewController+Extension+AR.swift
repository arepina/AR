//
//  MapViewController+Extension+AR.swift
//  AR
//
//  Created by Анастасия on 15/02/2019.
//  Copyright © 2019 Anastasia. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit
import SceneKit
import ARKit
import MapKit
import SwiftLocation
import ARCL
import Crashlytics
import SwiftExceptionCatcher
import AVFoundation

extension MapViewController {
    func initAR(){
        refresh.isHidden = true
        
        sceneView = SceneLocationView()
        sceneView.showsStatistics = false
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true
        sceneView.orientToTrueNorth = true
        
        let pressView : UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onSceneTap))
        sceneView.addGestureRecognizer(pressView)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.worldAlignment = .gravityAndHeading
        
        sceneView.session.run(configuration)
        view.addSubview(sceneView)
        view.addSubview(map)
        view.addSubview(buttons)
    }
    
    @objc func onSceneTap() {
        if map.isHidden{
            map.isHidden = false
            buttons.isHidden = false
        }else{
            map.isHidden = true
            buttons.isHidden = true
        }
    }
    
    @IBAction func refreshRoute(_ sender: Any) {
        if ConnectionService.isConnectedToNetwork(){
            clear()
            let coordinate: CLLocationCoordinate2D = (SwiftLocation.Locator.currentLocation?.coordinate)!
            let lat:Double = coordinate.latitude
            let lon:Double = coordinate.longitude
            let dest : Route = Route(p: "", c: String(lat) + ";" + String(lon), k: "")
            destination = CLLocation(latitude: lat, longitude: lon)
            chooseNavigationType(dest: dest)
        }else{
            showToast(message: "No Internet connection!", isMenu: false)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sceneView.frame = view.bounds
        buttons.frame = CGRect(
            x: self.view.frame.size.width - 40,
            y: self.view.frame.size.height / 2 + 10,
            width: 50,
            height: 180)
        map.frame = CGRect(
            x: 0,
            y: self.view.frame.size.height / 2,
            width: self.view.frame.size.width,
            height: self.view.frame.size.height / 2)
    }
    
    func drawRouteInAR(destination : Route){
        refresh.isHidden = false
        let request = MKDirections.Request()
        navigationService.calculateSteps(destination: destination, request: request) { route in
            //Map steps
            for index in 0..<route.instructions.count{
                self.poiHolder.annotationInstructions.append(route.instructions[index])
            }
            self.navigationService.updatedLocations.append(SwiftLocation.Locator.currentLocation!)
            self.instructions = route.instructions
            //AR steps
            let route = route.steps
                .map { self.navigationService.convert(scnView: self.sceneView, coordinate: $0) } // convert all the coordinates to the AR suitable
                .compactMap { $0 } // remove the nils
                .map { CGPoint(position: $0) } // combine the points
            self.addMapAnnotations() // map
            self.routeNodes = self.navigationService.setNavigation(forRoute: route) // AR
            //AR step's labels
            let nodes : [CGPoint] = self.poiHolder.annotationInstructions
                .map { self.navigationService.convert(scnView: self.sceneView, coordinate: $0.coordinate)} // convert all the coordinates to the AR suitable
                .compactMap { $0 } // remove the nils
                .map { CGPoint(position: $0)} // combine the points
            self.instructionNodes = self.navigationService.setExtraNodes(nodes: nodes, objects: self.poiHolder.annotationInstructions)// AR
            //finish label
            self.finishInfo(route : route)
            // zoom in to the current user's location
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let region = MKCoordinateRegion(center: SwiftLocation.Locator.currentLocation!.coordinate, span: span)
            self.map.setRegion(region, animated: true)
        }
    }
    
    func finishInfo(route : [CGPoint]){
        self.routeFinishNode = SCNNode()
        self.routeFinishNode!.position = route.last!.positionInAR
        self.routeFinishView = UIView()
        let imageName = "finish"
        let image = UIImage(named: imageName)
        let imageView = UIImageView(image: image!)
        imageView.frame = CGRect(x: -10, y: -10, width: 64, height: 64)
        self.routeFinishView!.addSubview(imageView)
        
        self.routeDistanceLabel = UILabel()
        self.routeDistanceLabel!.textColor = .white
        self.routeDistanceLabel!.font = UIFont.systemFont(ofSize: 26.0, weight: .bold)
        self.routeDistanceLabel!.numberOfLines = 1
        self.routeDistanceLabel!.layer.shadowRadius = 2.0
        self.routeDistanceLabel!.layer.shadowColor = UIColor.black.cgColor
        self.routeDistanceLabel!.layer.shadowOpacity = 1.0
        self.routeDistanceLabel!.layer.shadowOffset = CGSize.zero
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        if self.instructions != nil{
            for index in 0..<self.instructions.count{
                let mainNode = self.instructions[index]
                let mainNodeCoordinate: CLLocation = CLLocation(latitude: mainNode.coordinate.latitude, longitude: mainNode.coordinate.longitude)
                print(mainNodeCoordinate.distance(from: SwiftLocation.Locator.currentLocation!))
                if mainNodeCoordinate.distance(from: SwiftLocation.Locator.currentLocation!) <= 10{ // distance less then 10 metres
                    let synth = AVSpeechSynthesizer()
                    let myUtterance = AVSpeechUtterance(string: mainNode.title!)
                    synth.speak(myUtterance)
                    self.instructions.remove(at: index) //remove those which already been pronounsed
                    break
                }
            }
        }
        guard let finishLocation = destination else { return }
        guard let routeFinishNode = routeFinishNode else { return }
        guard let parent = routeFinishNode.parent else { return }
        guard let pointOfView = renderer.pointOfView else { return }
        
        let projection = sceneView.projectPoint(routeFinishNode.worldPosition)
        var projectionPoint = CGPoint(x: CGFloat(projection.x), y: CGFloat(projection.y))
        let positionInPOV = parent.convertPosition(routeFinishNode.position, to: pointOfView)
        
        let annotationPositionInWorld = routeFinishNode.convertPosition(SCNVector3Make(0.0, 1.0, 0.0), to: nil)
        let annotationProjection = sceneView.projectPoint(annotationPositionInWorld)
        let annotationProjectionPoint = CGPoint(x: CGFloat(annotationProjection.x), y: CGFloat(annotationProjection.y))
        let rotationAngle = Vector.y.angle(with: (Vector(annotationProjectionPoint) - Vector(projectionPoint)))
        var distance = round(SwiftLocation.Locator.currentLocation!.distance(from: finishLocation))
        distance = distance.isNaN ? 0.0 : distance
        if(projectionPoint.x.isNaN){
            projectionPoint.x = 0
        }
        if(projectionPoint.y.isNaN){
            projectionPoint.y = 0
        }
        do{
            try tryOp() {
                DispatchQueue.main.async { [weak self] in
                    if (self!.routeFinishView == nil){
                        self!.routeFinishView = UIView()
                    }
                    if (self!.routeDistanceLabel == nil){
                        self!.routeDistanceLabel = UILabel()
                    }
                    let placemarkSize = self!.placemarkSize(
                        forDistance: CGFloat(distance),
                        closeDistance: 10.0,
                        farDistance: 25.0,
                        closeDistanceSize: 100.0,
                        farDistanceSize: 50.0
                    )
                    let screenMidToProjectionLine = CGLine(point1: UIScreen.main.bounds.mid, point2: projectionPoint)
                    let distanceAttrStr = NSMutableAttributedString(string: "\(distance) м", attributes: [
                        .strokeColor : UIColor.black,
                        .foregroundColor : UIColor.white,
                        .strokeWidth : -1.0,
                        .font : UIFont.boldSystemFont(ofSize: 32.0)
                        ])
                    
                    let size = distanceAttrStr.boundingSize(width: .greatestFiniteMagnitude)
                    
                    self!.routeFinishView!.isHidden = !(positionInPOV.z < 0 && screenMidToProjectionLine.intersection(withRect: UIScreen.main.bounds) == nil)
                    self!.routeDistanceLabel!.isHidden = self!.routeFinishView!.isHidden
                    self!.routeFinishView!.center = projectionPoint
                    
                    self!.routeFinishView!.bounds.size.width = placemarkSize
                    self!.routeFinishView!.bounds.size.height = placemarkSize
                    self!.routeFinishView!.layer.cornerRadius = placemarkSize / 2
                    
                    self!.routeDistanceLabel!.attributedText = distanceAttrStr
                    self!.routeDistanceLabel!.center = projectionPoint
                    self!.routeDistanceLabel!.bounds.size = size
                    self!.routeDistanceLabel!.transform = CGAffineTransform(rotationAngle: CGFloat(rotationAngle - .pi))
                }
            }
        }
        catch let ex {
            print("Exception:", ex)
        }
    }
    
    func placemarkSize(forDistance distance: CGFloat, closeDistance: CGFloat, farDistance: CGFloat,
                       closeDistanceSize: CGFloat, farDistanceSize: CGFloat) -> CGFloat
    {
        guard closeDistance >= 0 else { assert(false); return 0.0 }
        guard closeDistance >= 0, farDistance >= 0, closeDistance <= farDistance else { assert(false); return 0.0 }
        
        if distance > farDistance {
            return farDistanceSize
        } else if distance < closeDistance{
            return closeDistanceSize
        } else {
            let delta = farDistanceSize - closeDistanceSize
            guard farDistance - closeDistance != 0 else { assert(false); return 0.0 }
            let percent: CGFloat = ((distance - closeDistance) / (farDistance - closeDistance))
            let size = closeDistanceSize + delta * percent
            return size
        }
    }
    
    func textToSpeech(text: String){
        let synth = AVSpeechSynthesizer()
        let myUtterance = AVSpeechUtterance(string: text)
        myUtterance.rate = 0.3
        synth.speak(myUtterance)
    }
}

