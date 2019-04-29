//
//  Widget.swift
//  AR
//
//  Created by Анастасия on 26/04/2019.
//  Copyright © 2019 Anastasia. All rights reserved.
//

import UIKit
import Firebase

class Widget{
    static func search(mainStoryboard: UIStoryboard, window: inout UIWindow?){
        let innerPage: LoginViewController = mainStoryboard.instantiateViewController(withIdentifier: "logInStoryBoard") as! LoginViewController
        window?.rootViewController = innerPage
        window?.makeKeyAndVisible()
    }
    
    static func favorite(mainStoryboard: UIStoryboard, window: inout UIWindow?){
        if Auth.auth().currentUser != nil { // check if user already logged in
            let innerPage: LoginViewController = mainStoryboard.instantiateViewController(withIdentifier: "logInStoryBoard") as! LoginViewController
            window?.rootViewController = innerPage
            window?.makeKeyAndVisible()
            if ConnectionService.isConnectedToNetwork(){
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    let topController = UIApplication.topViewController()
                    let c = topController as! MapViewController
                    c.performSegue(withIdentifier: "FavoriteNow", sender: nil)
                }
            }else{
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    UIApplication.topViewController()!.showToast(message: "No Internet connection!", isMenu: false)
                }
            }
        }else{
            let innerPage: LoginViewController = mainStoryboard.instantiateViewController(withIdentifier: "logInStoryBoard") as! LoginViewController
            window?.rootViewController = innerPage
            window?.makeKeyAndVisible()
        }
    }
    
    static func museum(mainStoryboard: UIStoryboard, window: inout UIWindow?){
        let innerPage: UINavigationController = mainStoryboard.instantiateViewController(withIdentifier: "mapNav") as! UINavigationController
        window?.rootViewController = innerPage
        window?.makeKeyAndVisible()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let topController = UIApplication.topViewController()
            let c = topController as! MapViewController
            c.museumBtn.sendActions(for: .touchUpInside)
        }
    }
    
    static func theater(mainStoryboard: UIStoryboard, window: inout UIWindow?){
        let innerPage: UINavigationController = mainStoryboard.instantiateViewController(withIdentifier: "mapNav") as! UINavigationController
        window?.rootViewController = innerPage
        window?.makeKeyAndVisible()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let topController = UIApplication.topViewController()
            let c = topController as! MapViewController
            c.theaterBtn.sendActions(for: .touchUpInside)
        }
    }

}
