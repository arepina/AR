//
//  SettingsWalkthoughContentViewController.swift
//  AR
//
//  Created by Анастасия on 28/11/2018.
//  Copyright © 2018 Anastasia. All rights reserved.
//

import UIKit

class SettingsWalkthroughContentViewController: UIViewController {
    
    @IBOutlet weak var contentImageView: UIImageView!
    
    var index = 0
    var imageFile = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        contentImageView.image = UIImage(named: imageFile)
    }
}
