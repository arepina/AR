//
//  MapViewController+Extension+Search.swift
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

protocol HandleMapSearch: class {
    func searchOnMap(_ placemark:MKPlacemark)
}
