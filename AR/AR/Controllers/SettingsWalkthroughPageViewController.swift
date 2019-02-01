//
//  SettingsWalkthroughViewController.swift
//  AR
//
//  Created by Анастасия on 28/11/2018.
//  Copyright © 2018 Anastasia. All rights reserved.
//

import UIKit
import SideMenu
import Firebase
import MessageUI

class SettingsWalkthroughPageViewController : UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate{
    
    var walkthroughDelegate: SettingsWalkthroughPageViewControllerDelegate?
    
    var currentIndex = 0
    var pageImages = ["privacy", "location", "app_location", "while_using"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        delegate = self
        // Create the first walkthrough screen
        if let startingViewController = contentViewController(at: 0) {
            setViewControllers([startingViewController], direction: .forward, animated: true, completion: nil)
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        var index = (viewController as! SettingsWalkthroughContentViewController).index
        index -= 1
        return contentViewController(at: index)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        var index = (viewController as! SettingsWalkthroughContentViewController).index
        index += 1        
        return contentViewController(at: index)
    }
    
    func contentViewController(at index: Int) -> SettingsWalkthroughContentViewController? {
        if index < 0 || index >= pageImages.count {
            return nil
        }
        // Create a new view controller and pass suitable data
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let pageContentViewController = storyboard.instantiateViewController(withIdentifier: "SettingsWalkthroughContentViewController") as? SettingsWalkthroughContentViewController {
            pageContentViewController.imageFile = pageImages[index]
            pageContentViewController.index = index
            return pageContentViewController
        }
        return nil
    }
    
    func forwardPage() {
        currentIndex += 1
        if let nextViewController = contentViewController(at: currentIndex) {
            setViewControllers([nextViewController], direction: .forward, animated: true, completion: nil)
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            if let contentViewController = pageViewController.viewControllers?.first as? SettingsWalkthroughContentViewController {
                currentIndex = contentViewController.index                
                walkthroughDelegate?.didUpdatePageIndex(currentIndex: currentIndex)
            }
        }
    }
}

protocol SettingsWalkthroughPageViewControllerDelegate: class {
    func didUpdatePageIndex(currentIndex: Int)
}

