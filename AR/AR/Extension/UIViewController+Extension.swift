//
//  Extension.swift
//  AR
//
//  Created by Анастасия on 01/12/2018.
//  Copyright © 2018 Anastasia. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

extension UIViewController {
    
    func showToast(message : String, isMenu : Bool) {
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 200, y: self.view.frame.size.height-100, width: 400, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center;
        toastLabel.font = UIFont(name: "Montserrat-Light", size: 12.0)
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        if(isMenu){
            self.parent?.view.addSubview(toastLabel)
        }else{
            self.view.addSubview(toastLabel)
        }
        UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
    
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
