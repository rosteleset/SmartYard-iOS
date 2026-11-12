//
//  UIViewController+Top.swift
//  SmartYard
//
//  Created by admin on 25.05.2020.
//  Copyright © 2021 Sesameware. All rights reserved.
//

import UIKit

extension UIViewController {
    
    var topViewController: UIViewController? { topViewController(includingPresented: true) }

    func topViewController(includingPresented: Bool) -> UIViewController? {
        if let navigationController = self as? UINavigationController {
            let child = includingPresented ? navigationController.visibleViewController : navigationController.viewControllers.last
            return child?.topViewController(includingPresented: includingPresented)
        }

        if let tabBarController = self as? UITabBarController {
            return tabBarController.selectedViewController?.topViewController(includingPresented: includingPresented)
        }

        if includingPresented, let presentedController = presentedViewController {
            return presentedController.topViewController(includingPresented: true)
        }
        return self
    }

}
