//
//  TodayViewController.swift
//  Widget
//
//  Created by Анастасия on 26/01/2019.
//  Copyright © 2019 Anastasia. All rights reserved.
//

import UIKit
import NotificationCenter

class WidgetViewController: UIViewController, NCWidgetProviding {
    
    @IBAction func search(_ sender: Any) {
        let url: NSURL = NSURL(string: "ARnavigation://host/search")!
        self.extensionContext?.open(url as URL, completionHandler: nil)
    }
    
    @IBAction func fav(_ sender: Any) {
        let url: NSURL = NSURL(string: "ARnavigation://host/favorite")!
        self.extensionContext?.open(url as URL, completionHandler: nil)
    }
    
    @IBAction func museum(_ sender: Any) {
        let url: NSURL = NSURL(string: "ARnavigation://host/museum")!
        self.extensionContext?.open(url as URL, completionHandler: nil)
    }
    
    @IBAction func theater(_ sender: Any) {
        let url: NSURL = NSURL(string: "ARnavigation://host/theater")!
        self.extensionContext?.open(url as URL, completionHandler: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        completionHandler(NCUpdateResult.newData)
    }
    
}
