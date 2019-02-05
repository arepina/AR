//
//  AppDelegate.swift
//  AR
//
//  Created by Анастасия on 07/11/2018.
//  Copyright © 2018 Anastasia. All rights reserved.
//

import UIKit
import Firebase
import Fabric
import Crashlytics
import SideMenu


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    var restrictRotation:UIInterfaceOrientationMask = .portrait


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()        
        Fabric.with([Crashlytics.self])
        
        application.isIdleTimerDisabled = true

        return true
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask
    {
        return self.restrictRotation
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        let urlPath : String = url.path as String
        let urlHost : String = url.host as! String
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        if(urlHost != "host")
        {
            print("Host is not correct")
            return false
        }        
        if(urlPath == "/search"){
            let innerPage: LoginViewController = mainStoryboard.instantiateViewController(withIdentifier: "logInStoryBoard") as! LoginViewController
            self.window?.rootViewController = innerPage
            self.window?.makeKeyAndVisible()
        } else if (urlPath == "/favorite"){
            if Auth.auth().currentUser != nil { // check if user already logged in
                let innerPage: LoginViewController = mainStoryboard.instantiateViewController(withIdentifier: "logInStoryBoard") as! LoginViewController
                self.window?.rootViewController = innerPage
                self.window?.makeKeyAndVisible()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    let topController = UIApplication.topViewController()
                    let c = topController as! MapViewController
                    c.performSegue(withIdentifier: "FavoriteNow", sender: nil)
                }
                
            }else{
                let innerPage: LoginViewController = mainStoryboard.instantiateViewController(withIdentifier: "logInStoryBoard") as! LoginViewController
                self.window?.rootViewController = innerPage
                self.window?.makeKeyAndVisible()
            }
        }
        else if (urlPath == "/museum"){
            let innerPage: UINavigationController = mainStoryboard.instantiateViewController(withIdentifier: "mapNav") as! UINavigationController
            self.window?.rootViewController = innerPage
            self.window?.makeKeyAndVisible()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                let topController = UIApplication.topViewController()
                let c = topController as! MapViewController
                c.museumBtn.sendActions(for: .touchUpInside)
            }
        }
        else if (urlPath == "/theater"){
            let innerPage: UINavigationController = mainStoryboard.instantiateViewController(withIdentifier: "mapNav") as! UINavigationController
            self.window?.rootViewController = innerPage
            self.window?.makeKeyAndVisible()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                let topController = UIApplication.topViewController()
                let c = topController as! MapViewController
                c.theaterBtn.sendActions(for: .touchUpInside)
            }
        }
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

