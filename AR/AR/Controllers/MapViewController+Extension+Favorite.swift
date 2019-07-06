//
//  MapViewController+Extension+Favorite.swift
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
import Firebase

extension MapViewController{
    @IBAction func addToFavorite(_ sender: Any) {
        if ConnectionService.isConnectedToNetwork(){
            var message : String
            var coordinates : CLLocationCoordinate2D
            if myRoute != nil{ // we need to add the destination location to favorite
                message = NSLocalizedString("ADD_DESTINATION_TO_FAVORITE", comment:"")
                coordinates = destination.coordinate
            }else{ // we need to add the user's location to favorite
                message = NSLocalizedString("ADD_CURRENT_TO_FAVORITE", comment:"")
                coordinates = SwiftLocation.Locator.currentLocation!.coordinate
            }
            let refreshAlert = UIAlertController(title: "❤️", message: message, preferredStyle: UIAlertController.Style.alert)
            refreshAlert.addTextField { (textField) in
                textField.placeholder = NSLocalizedString("ENTER_THE_NAME", comment:"")
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
