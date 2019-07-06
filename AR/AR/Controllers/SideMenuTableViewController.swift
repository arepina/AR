//
//  SideMenuTableViewController.swift
//  AR
//
//  Created by Анастасия on 20/11/2018.
//  Copyright © 2018 Anastasia. All rights reserved.
//

import Foundation
import SideMenu
import Firebase

class SideMenuTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource  {
    let menu = [NSLocalizedString("ROUTES", comment:""),
                NSLocalizedString("SETTINGS", comment:""),
                NSLocalizedString("INFO", comment:"")]
    @IBOutlet var table: UITableView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        table.delegate = self
        table.dataSource = self
    }    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menu.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MenuCell", for: indexPath as IndexPath)
        let row = indexPath.row
        cell.textLabel?.textColor = UIColor(red: 233.0/255, green: 57.0/255, blue: 57.0/255, alpha: 1.0)
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.font = UIFont.systemFont(ofSize: 22.0)
        cell.textLabel?.text = menu[row]
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if(ConnectionService.isConnectedToNetwork()){
            switch indexPath.row {
            case 0:
                if Auth.auth().currentUser != nil { // check if user already logged in
                    self.performSegue(withIdentifier: "Routes", sender: self)
                }else{
                    DispatchQueue.main.async {
                        self.performSegue(withIdentifier: "UnknownUser", sender: self)
                    }
                }
            case 1:
                if Auth.auth().currentUser != nil { // check if user already logged in
                    self.performSegue(withIdentifier: "Settings", sender: self)
                }else{
                    DispatchQueue.main.async {
                        self.performSegue(withIdentifier: "UnknownUser", sender: self)
                    }
                }
            default:
                self.performSegue(withIdentifier: "Info", sender: self)
            }
        }
        else{
            showToast(message: "No Internet connection!", isMenu: true)
        }
    }
}
