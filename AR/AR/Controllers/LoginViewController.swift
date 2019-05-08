//
//  ViewController.swift
//  AR
//
//  Created by Анастасия on 07/11/2018.
//  Copyright © 2018 Anastasia. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Firebase

class LoginViewController: UIViewController{
    
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var intro: UISegmentedControl!
    @IBOutlet weak var go: UIButton!
    @IBOutlet var viewWrapper: UIStackView!
    
    var isSignIn:Bool = true
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround() // do not show keyboard when tapped
        self.navigationController?.navigationBar.isHidden = true; // hide the nabigation bar
        DispatchQueue.main.async {
            if Auth.auth().currentUser != nil { // check if user already logged in
                self.performSegue(withIdentifier: "LogIn", sender: self)
            }else{
                self.viewWrapper.isHidden = false
            }
        }
    }
    
    @IBAction func introStateChanged(_ sender: Any) {
        isSignIn = !isSignIn
        if isSignIn{
            go.setTitle("Sign In", for: .normal)
        }
        else{
            go.setTitle("Register", for: .normal)
        }
    }
    
    @IBAction func goClick(_ sender: UIButton) {
        if ConnectionService.isConnectedToNetwork(){
            if !validateData(){return}
            if let e = email.text, let p = password.text
            {
                if(isSignIn){ // existing user
                    signIn(e: e, p: p)
                }else{ // new user
                    signUp(e: e, p: p)
                }
            }
        }else{
            showToast(message: "No Internet connection!", isMenu: false)
        }
    }
    
    func signIn(e : String, p : String){
        Auth.auth().signIn(withEmail: e, password: p) { (user, error) in
            if user != nil{
                self.performSegue(withIdentifier: "LogIn", sender: self)
            }else{
                if error.debugDescription.contains("17011"){
                    self.showToast(message: "User with these credentials does not exist", isMenu: false)
                }else if error.debugDescription.contains("17009"){
                    self.showToast(message: "Incorrect password", isMenu: false)
                }else{
                    self.showToast(message: "There was an error during the sign in. Try again", isMenu: false)
                }
            }
        }
    }
    
    func signUp(e : String, p : String){
        Auth.auth().createUser(withEmail: e, password: p) { (user, error) in
            if user != nil{
                self.performSegue(withIdentifier: "LogIn", sender: self)
            }else{
                if error.debugDescription.contains("17007"){
                    self.showToast(message: "User with these credentials already exist", isMenu: false)
                }else{
                    self.showToast(message: "There was an error during the sign up. Try again", isMenu: false)
                }
            }
        }
    }
    
    func validateData() -> Bool{
        if email.text == "" || password.text == ""{
            self.showToast(message: "Enter all the data", isMenu: false)
            return false
        }
        if (password.text?.count)! < 6{
            self.showToast(message: "The password size should be not less then 6", isMenu: false)
            return false
        }
        if !validateEmail(testStr: email.text!){
            self.showToast(message: "The email is incorrect", isMenu: false)
            return false
        }
        return true
    }
    
    func validateEmail(testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
}
