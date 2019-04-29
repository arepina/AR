//
//  MapViewController.swift
//  AR
//
//  Created by Анастасия on 19/11/2018.
//  Copyright © 2018 Anastasia. All rights reserved.
//

import UIKit
import SideMenu
import SceneKit
import ARKit
import MapKit
import CoreLocation
import Firebase
import FirebaseDatabase
import SwiftLocation
import SwiftSpinner
import ARCL

class MapViewController :  UIViewController, ARSCNViewDelegate, ARSessionDelegate{
    @IBOutlet var museumBtn: UIButton! // museum btn
    @IBOutlet var theaterBtn: UIButton! // theater btn
    @IBOutlet var buttons: UIStackView!// buttons view
    @IBOutlet var sceneView: SceneLocationView! // AR view
    @IBOutlet var map: MKMapView! // map view
    @IBOutlet var refresh: UIButton!
    
    var navigationService : NavigationService! // navigation service
    var myRoute : MKRoute! // route on the map
    var resultSearchController: UISearchController! // search result
    var favoriteRoute: Route! // favorite route
    var destination : CLLocation! // destination
    var poiHolder : PointOfInterestHolder! // POIs
    var isFirst : Bool! // is first run of the location detector
    
    var routeNodes: [SCNNode] = [] {
        didSet {
            oldValue.forEach { $0.removeFromParentNode() }
            routeNodes.forEach {
                sceneView.scene.rootNode.addChildNode($0)
            }
        }
    }
    
    var museumNodes: [SCNNode] = [] {
        didSet {
            oldValue.forEach { $0.removeFromParentNode() }
            museumNodes.forEach {
                sceneView.scene.rootNode.addChildNode($0)
            }
        }
    }
    
    var theaterNodes: [SCNNode] = [] {
        didSet {
            oldValue.forEach { $0.removeFromParentNode() }
            theaterNodes.forEach {
                sceneView.scene.rootNode.addChildNode($0)
            }
        }
    }
    
    var instructionNodes: [SCNNode] = [] {
        didSet {
            oldValue.forEach { $0.removeFromParentNode() }
            instructionNodes.forEach {
                sceneView.scene.rootNode.addChildNode($0)
            }
        }
    }
    
    var routeDistanceLabel: UILabel? = nil {
        didSet {
            oldValue?.removeFromSuperview()
            if let label = routeDistanceLabel {
                view.addSubview(label)
            }
        }
    }
    
    var routeFinishNode: SCNNode? = nil {
        didSet {
            oldValue?.removeFromParentNode()
            if let node = routeFinishNode {
                sceneView.scene.rootNode.addChildNode(node)
            }
        }
    }
    
    var routeFinishView: UIView? = nil {
        didSet {
            oldValue?.removeFromSuperview()
            if let routeFinishView = routeFinishView {
                view.addSubview(routeFinishView)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if ARConfiguration.isSupported {
            isFirst = true
            initAR()
            initSearch()
            initMap()
            Locator.requestAuthorizationIfNeeded(.always)
            Locator.subscribePosition(accuracy: .city, onUpdate: { loc in
                if(self.isFirst){
                    self.isFirst = false
                    // zoom in to the current user's location
                    let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    let region = MKCoordinateRegion(center: SwiftLocation.Locator.currentLocation!.coordinate, span: span)
                    self.map.setRegion(region, animated: true)
                }
            }, onFail: {err, last in
                print("Failed with error: \(err)")
            })
            if(favoriteRoute != nil){ // has choosen a favorite route -> load it
                let lat:Double = favoriteRoute.coordinates!.latitude
                let lon:Double = favoriteRoute.coordinates!.longitude
                destination = CLLocation(latitude: lat, longitude: lon)
                clear()
                drawRouteOnMap(destination: favoriteRoute)
                drawRouteInAR(destination: favoriteRoute)
                favoriteRoute = nil
            }
        } else {
            showToast(message: "ARKit is not compatible with your phone", isMenu: false)
            return
        }
    }
    
    @IBAction func menuClick(_ sender: Any) {
        performSegue(withIdentifier: "openMenu", sender: nil)
    }
    
    func clear(){
       sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
            node.removeFromParentNode() }
       clearMap()
       clearButtons()
    }
    
    func clearMap(){
        poiHolder = PointOfInterestHolder()
        myRoute = nil
        destination = nil
        routeDistanceLabel = nil
        routeFinishNode = nil
        routeFinishView = nil
        map.removeAnnotations(map.annotations)
        map.removeOverlays(map.overlays)
    }
    
    func clearButtons(){
        museumBtn.layer.shadowColor = UIColor.clear.cgColor
        museumBtn.layer.shadowOffset = CGSize(width: 0, height: 0)
        museumBtn.layer.shadowOpacity = 0.0
        museumBtn.layer.shadowRadius = 0.0
        
        theaterBtn.layer.shadowColor = UIColor.clear.cgColor
        theaterBtn.layer.shadowOffset = CGSize(width: 0, height: 0)
        theaterBtn.layer.shadowOpacity = 0.0
        theaterBtn.layer.shadowRadius = 0.0
        
        refresh.isHidden = true
    }
    
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        initAR()
        return true
    }
}
