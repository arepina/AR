//
//  MapViewController+Extension+Map.swift
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
import Crashlytics

extension MapViewController: MKMapViewDelegate {
    func initMap(){
        navigationService = NavigationService()
        poiHolder = PointOfInterestHolder()
        let pressMap : UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(onMapPress(gesture:)))
        pressMap.minimumPressDuration = 0.35
        map.showsUserLocation = true
        map.addGestureRecognizer(pressMap)
        map.delegate = self
        map.showsScale = true
        map.showsCompass = false
        let compassButton : MKCompassButton = MKCompassButton(mapView: map)
        compassButton.compassVisibility = .adaptive
        map.addSubview(compassButton)
        compassButton.translatesAutoresizingMaskIntoConstraints = false
        compassButton.trailingAnchor.constraint(equalTo: map.trailingAnchor, constant: -self.view.frame.size.width + 50).isActive = true
        compassButton.topAnchor.constraint(equalTo: map.topAnchor, constant: 40).isActive = true
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
            let from = String(SwiftLocation.Locator.currentLocation!.coordinate.latitude) + ";" + String(SwiftLocation.Locator.currentLocation!.coordinate.longitude)
            let to = String(lat) + ";" + String(lon)
            let dest : Route = Route(p: "", c: to, k: "")
            print(from)
            print(to)
            CLSLogv("from: %@", getVaList([from]))
            CLSLogv("to: %@", getVaList([to]))
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
