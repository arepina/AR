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
import ARCL
import SwiftSpinner

class MapViewController :  UIViewController, ARSCNViewDelegate, ARSessionDelegate{
    @IBOutlet var museumBtn: UIButton! // museum btn
    @IBOutlet var theaterBtn: UIButton! // theater btn
    @IBOutlet var buttons: UIStackView!// buttons view
    @IBOutlet var sceneView: SceneLocationView! // AR view
    @IBOutlet var map: MKMapView! // map view
    
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
    }
}

extension MapViewController{
    @IBAction func addToFavorite(_ sender: Any) {
        if ConnectionService.isConnectedToNetwork(){
            var message : String
            var coordinates : CLLocationCoordinate2D
            if myRoute != nil{ // we need to add the destination location to favorite
                message = "Add the destination location to favorite?"
                coordinates = destination.coordinate
            }else{ // we need to add the user's location to favorite
                message = "Add your current location to favorite?"
                coordinates = SwiftLocation.Locator.currentLocation!.coordinate
            }
            let refreshAlert = UIAlertController(title: "❤️", message: message, preferredStyle: UIAlertController.Style.alert)
            refreshAlert.addTextField { (textField) in
                textField.placeholder = "Enter the name for a favorite place"
            }
            refreshAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
                let placeName = refreshAlert.textFields![0].text! as String
                FirebaseService.addRoute(userID: (Auth.auth().currentUser?.uid)!, coordinate: coordinates, placeName: placeName)
                self.showToast(message: "Added!", isMenu: false)
            }))
            refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
                //do nothing
            }))
            present(refreshAlert, animated:true, completion: nil)
        }else{
            showToast(message: "No Internet connection!", isMenu: false)
        }
    }
}

extension MapViewController: MKMapViewDelegate {
    func initMap(){
        navigationService = NavigationService()
        poiHolder = PointOfInterestHolder()
        let pressMap : UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(onMapPress(gesture:)))
//        let tapMap : UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onMapTap))
        pressMap.minimumPressDuration = 0.35
        map.showsUserLocation = true
        map.addGestureRecognizer(pressMap)
//        map.addGestureRecognizer(tapMap)
        map.delegate = self
    }
    
    @objc func onMapPress(gesture: UIGestureRecognizer) {
        if ConnectionService.isConnectedToNetwork(){
            if gesture.state != UIGestureRecognizer.State.began {
                return
            }
            clear()
            let touchPoint = gesture.location(in: map)
            let coordinate: CLLocationCoordinate2D = map.convert(touchPoint, toCoordinateFrom: map)
            let lat:Double = coordinate.latitude
            let lon:Double = coordinate.longitude
            let dest : Route = Route(p: "", c: String(lat) + ";" + String(lon), k: "")
            destination = CLLocation(latitude: lat, longitude: lon)
            drawRouteOnMap(destination: dest)
            drawRouteInAR(destination: dest)
        }else{
            showToast(message: "No Internet connection!", isMenu: false)
        }
    }
    
//    @objc func onMapTap(gesture: UIGestureRecognizer) {
//        if sceneView.isHidden{
//            sceneView.isHidden = false
//            map.frame = CGRect(
//                x: 0,
//                y: self.view.frame.size.height / 2,
//                width: self.view.frame.size.width,
//                height: self.view.frame.size.height / 2)
//        }else{
//            sceneView.isHidden = true
//            map.frame = CGRect(
//                x: 0,
//                y: 0,
//                width: self.view.frame.size.width,
//                height: self.view.frame.size.height)
//        }
//    }
    
    @IBAction func clearMap(_ sender: Any) {
        clear()
    }
    
    func drawRouteOnMap(destination : Route){
        map.setRegion(MKCoordinateRegion(center: destination.coordinates!, span: MKCoordinateSpan(latitudeDelta: 0.05,longitudeDelta: 0.05)), animated: true) // center the image
        let directionsRequest = MKDirections.Request()
        let fromMark = MKPlacemark(coordinate: SwiftLocation.Locator.currentLocation!.coordinate, addressDictionary: nil)
        let toMark = MKPlacemark(coordinate: destination.coordinates!, addressDictionary: nil)
        directionsRequest.source = MKMapItem(placemark: fromMark) // start point
        directionsRequest.destination = MKMapItem(placemark: toMark) // end point
        directionsRequest.transportType = MKDirectionsTransportType.walking // on foot
        MKDirections(request: directionsRequest).calculate(completionHandler: {
            response, error in
            if error == nil {
                self.myRoute = response!.routes[0] as MKRoute // set the first of found routes
                self.map.addOverlay(self.myRoute.polyline) // draw route on the map
                self.showToast(message: "Distance: \(self.myRoute.distance)m Duration: \(round(self.myRoute.expectedTravelTime / 60))min", isMenu: false)
            }
        })
    }
    
    func addMapAnnotations() {
        poiHolder.annotationInstructions.forEach { instruction in
            DispatchQueue.main.async {
                self.map.addAnnotation(instruction)
                self.map.addOverlay(MKCircle(center: instruction.coordinate, radius: 0.3))
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        let pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
        pinView.canShowCallout = true
        pinView.animatesDrop = false
        pinView.pinTintColor = UIColor.blue
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) ->MKOverlayRenderer {
        if overlay is MKCircle {
            let renderer = MKCircleRenderer(overlay: overlay)
            renderer.fillColor = UIColor.black.withAlphaComponent(0.1)
            renderer.strokeColor = UIColor.blue
            renderer.lineWidth = 4
            return renderer
        }else{
            let myLineRenderer = MKPolylineRenderer(polyline: myRoute.polyline)
            myLineRenderer.strokeColor = UIColor.blue
            myLineRenderer.lineWidth = 2
            return myLineRenderer
        }
    }
}

extension MapViewController: HandleMapSearch {
    func initSearch(){
        let locationSearchTable = storyboard!.instantiateViewController(withIdentifier: "setupRouteViewController") as! SetupRouteViewController
        resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultSearchController.searchResultsUpdater = locationSearchTable
        let searchBar = resultSearchController!.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = "Search..."
        navigationItem.titleView = resultSearchController?.searchBar
        resultSearchController.hidesNavigationBarDuringPresentation = false
        resultSearchController.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
        locationSearchTable.mapView = map
        locationSearchTable.handleMapSearchDelegate = self
    }
    
    func searchOnMap(_ placemark: MKPlacemark){
        if ConnectionService.isConnectedToNetwork(){
            clear()
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = placemark.coordinate
            annotation.title = placemark.name
            if let city = placemark.locality, let state = placemark.administrativeArea {
                annotation.subtitle = "\(city) \(state)"
            }
            map.addAnnotation(annotation)
            
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let region = MKCoordinateRegion(center: placemark.coordinate, span: span)
            map.setRegion(region, animated: true)
            
            let lat:Double = placemark.coordinate.latitude
            let lon:Double = placemark.coordinate.longitude
            let dest : Route = Route(p: "", c: String(lat) + ";" + String(lon), k: "")
            destination = CLLocation(latitude: lat, longitude: lon)
            
            drawRouteOnMap(destination: dest)
            drawRouteInAR(destination: dest)
        }else{
            showToast(message: "No Internet connection!", isMenu: false)
        }
    }
    
    @IBAction func userLocation(_ sender: Any) {
        let currentLocation = MKPlacemark(coordinate: SwiftLocation.Locator.currentLocation!.coordinate, addressDictionary: nil)
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: currentLocation.coordinate, span: span)
        map.setRegion(region, animated: true)
    }
}

extension MapViewController {
    func initAR(){
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
        let request = MKDirections.Request()
        navigationService.calculateSteps(destination: destination, request: request) { route in
            var steps: [CLLocationCoordinate2D] = []
            for stepIndex in 0..<route.polyline.pointCount {
                let step: MKMapPoint = route.polyline.points()[stepIndex]
                steps.append(step.coordinate)
            }
            for stepIndex in 0..<route.steps.count{
                if route.steps[stepIndex].instructions != ""{
                    let poi : PointOfInterest = PointOfInterest(coordinate: route.steps[stepIndex].getLocation().coordinate, title: route.steps[stepIndex].instructions, color: .blue, image : UIImage())
                    self.poiHolder.annotationInstructions.append(poi)
                }
            }
            self.navigationService.updatedLocations.append(SwiftLocation.Locator.currentLocation!)
            //AR steps
            let route = steps
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
        self.routeFinishView!.backgroundColor = UIColor.red
        
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
        let currentLocation = SwiftLocation.Locator.currentLocation
        guard let finishLocation = destination else { return }
        guard let routeFinishNode = routeFinishNode else { return }
        guard let parent = routeFinishNode.parent else { return }
        guard let pointOfView = renderer.pointOfView else { return }
        
        let projection = sceneView.projectPoint(routeFinishNode.worldPosition)
        let projectionPoint = CGPoint(x: CGFloat(projection.x), y: CGFloat(projection.y))
        let positionInPOV = parent.convertPosition(routeFinishNode.position, to: pointOfView)
        
        let annotationPositionInWorld = routeFinishNode.convertPosition(SCNVector3Make(0.0, 1.0, 0.0), to: nil)
        let annotationProjection = sceneView.projectPoint(annotationPositionInWorld)
        let annotationProjectionPoint = CGPoint(x: CGFloat(annotationProjection.x), y: CGFloat(annotationProjection.y))
        let rotationAngle = Vector.y.angle(with: (Vector(annotationProjectionPoint) - Vector(projectionPoint)))
        let distance = round(currentLocation!.distance(from: finishLocation))
        
        DispatchQueue.main.async { [weak self] in
            guard let slf = self else { return }
            guard let routeFinishView = slf.routeFinishView else { return }
            guard let routeDistanceLabel = slf.routeDistanceLabel else { return }
            
            let placemarkSize = slf.placemarkSize(
                forDistance: CGFloat(distance),
                closeDistance: 10.0,
                farDistance: 25.0,
                closeDistanceSize: 100.0,
                farDistanceSize: 50.0
            )
            let screenMidToProjectionLine = CGLine(point1: UIScreen.main.bounds.mid, point2: projectionPoint)
            routeFinishView.isHidden = !(positionInPOV.z < 0 && screenMidToProjectionLine.intersection(withRect: UIScreen.main.bounds) == nil)
            routeDistanceLabel.isHidden = routeFinishView.isHidden
            
            routeFinishView.center = projectionPoint
            routeFinishView.bounds.size = CGSize(width: placemarkSize, height: placemarkSize)
            routeFinishView.layer.cornerRadius = placemarkSize / 2
            
            let distanceAttrStr = NSMutableAttributedString(string: "\(distance) м", attributes: [
                .strokeColor : UIColor.black,
                .foregroundColor : UIColor.white,
                .strokeWidth : -1.0,
                .font : UIFont.boldSystemFont(ofSize: 32.0)
                ])
            routeDistanceLabel.attributedText = distanceAttrStr
            routeDistanceLabel.center = projectionPoint
            let size = distanceAttrStr.boundingSize(width: .greatestFiniteMagnitude)
            routeDistanceLabel.bounds.size = size
            routeDistanceLabel.transform = CGAffineTransform(rotationAngle: CGFloat(rotationAngle - .pi))
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
            let percent: CGFloat = ((distance - closeDistance) / (farDistance - closeDistance))
            let size = closeDistanceSize + delta * percent
            return size
        }
    }
}

extension MapViewController{
    @IBAction func museumClick(_ sender: UIButton) {
        let toLoad : Bool = sender.layer.shadowColor != UIColor.green.cgColor
        clearObjects(sender)
        if toLoad {
            sender.layer.shadowColor = UIColor.green.cgColor
            sender.layer.shadowOffset = CGSize(width: 2, height: 2)
            sender.layer.shadowOpacity = 1.0
            sender.layer.shadowRadius = 0.0
            navigationService.updatedLocations.append(SwiftLocation.Locator.currentLocation!)
            let objects = ObjectsService.getObjects(fileName: "museums") // 54 objects + 1 extra for test purposes
            let nodes = objects
                .map { navigationService.convert(scnView: self.sceneView, coordinate: $0.coordinate)} // convert all the coordinates to the AR suitable
                .compactMap { $0 } // remove the nils
                .map { CGPoint(position: $0)} // combine the points
            for annotation in objects{
                map.addAnnotation(annotation)
                poiHolder.annotationMuseums.append(annotation)
            }
            museumNodes = navigationService.setExtraNodes(nodes: nodes, objects: objects)// AR
        }
    }
    
    @IBAction func theatersClick(_ sender: UIButton) {
        let toLoad : Bool = sender.layer.shadowColor != UIColor.green.cgColor
        clearObjects(sender)
        if toLoad {
            sender.layer.shadowColor = UIColor.green.cgColor
            sender.layer.shadowOffset = CGSize(width: 2, height: 2)
            sender.layer.shadowOpacity = 1.0
            sender.layer.shadowRadius = 0.0
            navigationService.updatedLocations.append(SwiftLocation.Locator.currentLocation!)
            let objects = ObjectsService.getObjects(fileName: "theaters")
            let nodes = objects
                .map { navigationService.convert(scnView: self.sceneView, coordinate: $0.coordinate)} // convert all the coordinates to the AR suitable
                .compactMap { $0 } // remove the nils
                .map { CGPoint(position: $0)} // combine the points
            for annotation in objects{
                map.addAnnotation(annotation)
                poiHolder.annotationTheaters.append(annotation)
            }
            theaterNodes = navigationService.setExtraNodes(nodes: nodes, objects : objects)// AR
        }
    }
    
    func clearObjects(_ sender : UIButton!){
        // remove all the objects from scene
        sender.layer.shadowColor = UIColor.clear.cgColor
        sender.layer.shadowOffset = CGSize(width: 0, height: 0)
        sender.layer.shadowOpacity = 0.0
        sender.layer.shadowRadius = 0.0
        clearButtons()
        museumNodes.removeAll()
        theaterNodes.removeAll()
        for ob in poiHolder.annotationTheaters{
            map.removeAnnotation(ob)
        }
        for ob in poiHolder.annotationMuseums{
            map.removeAnnotation(ob)
        }
    }
}

protocol HandleMapSearch: class {
    func searchOnMap(_ placemark:MKPlacemark)
}
