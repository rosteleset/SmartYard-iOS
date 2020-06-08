//
//  UIViewController+Top.swift
//  SmartYard
//
//  Created by admin on 25.05.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit

extension UIViewController {
    
    var topViewController: UIViewController? {
        if let navigationController = self as? UINavigationController {
            return navigationController.visibleViewController?.topViewController
        }
        
        if let tabBarController = self as? UITabBarController {
            return tabBarController.selectedViewController?.topViewController
        }
        
        if let presentedController = presentedViewController {
            return presentedController.topViewController
        }
        
        return self
    }
    
}
