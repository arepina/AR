//
//  RoutesTableViewCell.swift
//  AR
//
//  Created by Анастасия on 26/11/2018.
//  Copyright © 2018 Anastasia. All rights reserved.
//

import UIKit

class RoutesTableViewCell:UITableViewCell{
    
    @IBOutlet weak var place: UILabel!
    
    func setRoute(route : Route){
        place.text = route.place
    }
}

