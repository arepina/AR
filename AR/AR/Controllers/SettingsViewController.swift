//
//  SettingsViewController.swift
//  AR
//
//  Created by Анастасия on 19/11/2018.
//  Copyright © 2018 Anastasia. All rights reserved.
//

import UIKit
import SideMenu
import Firebase
import MessageUI

class SettingsViewController : UIViewController, SettingsWalkthroughPageViewControllerDelegate, MFMailComposeViewControllerDelegate{
    
    
    var settingsWalkthroughPageViewController: SettingsWalkthroughPageViewController?
    
    @IBOutlet weak var pageControl: UIPageControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func didUpdatePageIndex(currentIndex: Int) {
        pageControl.currentPage = currentIndex
    }
    
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destination = segue.destination
        if let pageViewController = destination as? SettingsWalkthroughPageViewController {
            settingsWalkthroughPageViewController = pageViewController
            settingsWalkthroughPageViewController?.walkthroughDelegate = self
        }
    }
    
    @IBAction func sendEmail(_ sender: Any) {
        let composer = MFMailComposeViewController()
        if MFMailComposeViewController.canSendMail() {
            composer.mailComposeDelegate = self
            composer.setToRecipients(["repina.developer@gmail.com"])
            composer.setSubject("AR Navigation app")
            composer.setMessageBody("", isHTML: false)
            present(composer, animated: true, completion: nil)
        }else{
            showToast(message: "Mail services are not available", isMenu: false)
        }
    }
    
    @IBAction func logOutClick(_ sender: Any) {
        if ConnectionService.isConnectedToNetwork(){
            do{
                try Auth.auth().signOut();
                self.performSegue(withIdentifier: "LogOut", sender: self)
            } catch let logoutError {
                print(logoutError)
            }
        }else{
            showToast(message: "No Internet connection!", isMenu: false)
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
