//
//  RoutesViewController.swift
//  AR
//
//  Created by Анастасия on 19/11/2018.
//  Copyright © 2018 Anastasia. All rights reserved.
//

import UIKit
import SideMenu
import Firebase
import SwiftSpinner

class RoutesViewController : UITableViewController{
    @IBOutlet var table: UITableView!
    var routes : [Route] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.table.estimatedRowHeight = self.table.rowHeight
        self.table.rowHeight = 66
        self.table.separatorColor = UIColor.red
        navigationItem.rightBarButtonItem = editButtonItem
        SwiftSpinner.show(NSLocalizedString("LOADING", comment:""))
        SwiftSpinner.setTitleColor(UIColor(red: 233.0/255, green: 57.0/255, blue: 57.0/255, alpha: 1.0)) 
        FirebaseService.getAllRoutes(userID: (Auth.auth().currentUser?.uid)!, callback: {(routes)-> (Void) in
            self.routes = routes
            self.table.reloadData()
            SwiftSpinner.hide()
        })
    }
}

extension RoutesViewController{
    override func tableView(_ table: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let route = self.routes[indexPath.row]
        let cell = table.dequeueReusableCell(withIdentifier: "RoutesTableViewCell") as! RoutesTableViewCell
        cell.setRoute(route : route)
        return cell
    }
    
    override func tableView(_ table: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.routes.count
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete{
            FirebaseService.removeRoute(userID: (Auth.auth().currentUser?.uid)!, key : routes[indexPath.row].key)
            routes.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let route = routes[indexPath.row]
        self.performSegue(withIdentifier: "Favorite", sender: route)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Favorite" {
            let controller = segue.destination as! MapViewController            
            controller.favoriteRoute = sender as? Route
        }
    }
}
