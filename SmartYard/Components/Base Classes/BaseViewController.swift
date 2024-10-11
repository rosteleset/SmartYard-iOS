//
//  BaseViewController.swift
//  SmartYard
//
//  Created by admin on 30/01/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SSCustomTabbar

class BaseViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
//        return .lightContent
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                if let tabBarVC = tabBarController as? SSCustomTabBarViewController, 
                    let tabBar = tabBarVC.tabBar as? SSCustomTabBar {
                    if traitCollection.userInterfaceStyle == .dark {
//                        tabBar.barStyle = .black
                    } else {
//                        tabBar.barStyle = .default
                    }
                }
//                mapView.mapboxMap.styleURI = StyleURI(url: traitCollection.userInterfaceStyle == .dark ? darkURL : lightURL)
            }
        }
    }
}
