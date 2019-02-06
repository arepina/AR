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
    @IBOutlet var pickerView: UIStackView! // pickerView
    @IBOutlet var picker: UIPickerView! // picker
    @IBOutlet var map: MKMapView! // map view
    var press: UILongPressGestureRecognizer! // user tap
    var navigationService = NavigationService() // navigation service
    let configuration = ARWorldTrackingConfiguration() // AR configuration
    var myRoute : MKRoute! // route on the map
    var resultSearchController: UISearchController! // search result
    var favoriteRoute: Route! // favorite route
    var annotations: [PointOfInterest] = [] // annotations for POI
    var legs: [[CLLocationCoordinate2D]] = [] // legs of the route
    var steps: [MKRoute.Step] = [] // steps of the route
    var nodes: [ARNode] = [] // AR nodes
    var destination : CLLocation! // destination
    var instructions : [String] = []
    var annotationMuseums : [PointOfInterest] = [] //  museums pins
    var annotationTheaters : [PointOfInterest] = [] //  theaters pins
    var isFirst : Bool!
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if ARConfiguration.isSupported {
            isFirst = true
            picker.delegate = self
            picker.dataSource = self
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
        steps = []
        annotations = []
        legs = []
        nodes = []
        instructions = []
        myRoute = nil
        destination = nil
        self.pickerView.isHidden = true
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
        press = UILongPressGestureRecognizer(target: self, action: #selector(onMapTap(gesture:)))
        press.minimumPressDuration = 0.35
        map.showsUserLocation = true
        map.addGestureRecognizer(press)
        map.delegate = self
    }
    
    @objc func onMapTap(gesture: UIGestureRecognizer) {
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
        annotations.forEach { annotation in
            DispatchQueue.main.async {
                if let title = annotation.title, title.hasPrefix("N") {
                    annotation.title!.remove(at: annotation.title!.startIndex) // remove the identify for steps N char
                }
                self.map.addAnnotation(annotation)
                self.map.addOverlay(MKCircle(center: annotation.coordinate, radius: 0.3))
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?{
        if annotation is MKUserLocation {
            return nil
        }
        let pin = annotation as? PointOfInterest
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: "pin") as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
            pinView!.canShowCallout = true
            pinView!.animatesDrop = false
            pinView!.pinTintColor = pin!.color
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView!
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
        sceneView.showsStatistics = true
        sceneView.run()
        view.addSubview(sceneView)
        view.addSubview(map)
        view.addSubview(buttons)
        view.addSubview(pickerView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sceneView.frame = view.bounds
        buttons.frame = CGRect(
            x: self.view.frame.size.width - 40,
            y: self.view.frame.size.height / 2 + 10,
            width: 50,
            height: 180)
        pickerView.frame = CGRect(
            x: 0,
            y: self.view.frame.size.height / 2 - 65,
            width: self.view.frame.size.width,
            height: 70.5)
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
                self.instructions.append(route.steps[stepIndex].instructions)
            }
            self.instructions = self.instructions.filter { $0 != "" }
            self.pickerView.isHidden = false
            self.picker.reloadAllComponents()
            self.navigationService.updatedLocations.append(SwiftLocation.Locator.currentLocation!)
            let route = steps
                .map { self.navigationService.convert(scnView: self.sceneView, coordinate: $0) } // convert all the coordinates to the AR suitable
                .compactMap { $0 } // remove the nils
                .map { CGPoint(position: $0) } // combine the points
            self.addMapAnnotations() // map
            self.routeNodes = self.navigationService.setNavigation(forRoute: route) // AR
            // zoom in to the current user's location
            guard let location = self.steps.first else { return }
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let region = MKCoordinateRegion(center: location.getLocation().coordinate, span: span)
            self.map.setRegion(region, animated: true)
        }
    }
}

extension MapViewController{
    @IBAction func museumClick(_ sender: UIButton) {
        if(map.annotations.count > 1 && nodes.count > 0){
            let refreshAlert = UIAlertController(title: "🏛", message: "You are going to switch to museums view mode! Is it ok?", preferredStyle: UIAlertController.Style.alert)
            refreshAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
                self.clearMap()
                self.loadMuseums(sender)
            }))
            refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
                //do nothing
            }))
            present(refreshAlert, animated:true, completion: nil)
        }else{
            loadMuseums(sender)
        }
    }
    
    @IBAction func theatersClick(_ sender: UIButton) {
        if(map.annotations.count > 1 && nodes.count > 0){
            let refreshAlert = UIAlertController(title: "🎭", message: "You are going to switch to theathers view mode! Is it ok?", preferredStyle: UIAlertController.Style.alert)
            refreshAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
                self.clearMap()
                self.loadTheathers(sender)
            }))
            refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
                //do nothing
            }))
            present(refreshAlert, animated:true, completion: nil)
        }else{
            loadTheathers(sender)
        }
    }
    
    func loadMuseums(_ sender: UIButton){
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
                .map { navigationService.convert(scnView: self.sceneView, coordinate: $0.location.coordinate)} // convert all the coordinates to the AR suitable
                .compactMap { $0 } // remove the nils
                .map { CGPoint(position: $0)} // combine the points
            annotationMuseums = ObjectsService.getAnnotations(objects: objects, color : UIColor.blue)
            for annotation in annotationMuseums{
                map.addAnnotation(annotation)
            }
            museumNodes = navigationService.setExtraNodes(nodes: nodes, objects: objects)// AR
        }
    }
    
    func loadTheathers(_ sender: UIButton){
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
                .map { navigationService.convert(scnView: self.sceneView, coordinate: $0.location.coordinate)} // convert all the coordinates to the AR suitable
                .compactMap { $0 } // remove the nils
                .map { CGPoint(position: $0)} // combine the points
            annotationTheaters = ObjectsService.getAnnotations(objects: objects, color : UIColor.blue)
            for annotation in annotationTheaters{
                map.addAnnotation(annotation)
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
        for ob in annotationTheaters{
            map.removeAnnotation(ob)
        }
        for ob in annotationMuseums{
            map.removeAnnotation(ob)
        }
    }
}

extension MapViewController : UIPickerViewDelegate, UIPickerViewDataSource{
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return instructions.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return instructions[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var pickerLabel: UILabel? = (view as? UILabel)
        if pickerLabel == nil {
            pickerLabel = UILabel()
            pickerLabel?.font = UIFont(name: "AvenirNext-Medium", size: 12)
            pickerLabel?.textAlignment = .center
        }
        pickerLabel?.text = instructions[row]
        pickerLabel?.textColor = UIColor.black
        return pickerLabel!
    }
}

protocol HandleMapSearch: class {
    func searchOnMap(_ placemark:MKPlacemark)
}
