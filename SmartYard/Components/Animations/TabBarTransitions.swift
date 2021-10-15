//
//  TabBarTransitions.swift
//  SmartYard
//
//  Created by admin on 07/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import XCoordinator

extension TabBarTransition {
    
    static func selectAndCallDelegate(_ presentable: Presentable, animation: Animation? = nil) -> Transition {
        return Transition(
            presentables: [presentable],
            animationInUse: animation?.presentationAnimation
        ) { tbc, _, _ in
            let firstMatch = tbc.viewControllers?.enumerated().first { args in
                let (_, element) = args
                return element == presentable.viewController
            }
            
            guard let index = firstMatch?.offset, let tabBarItem = firstMatch?.element.tabBarItem else {
                return
            }
            
            tbc.selectedIndex = index
            tbc.tabBar(tbc.tabBar, didSelect: tabBarItem)
        }
    }
    
}
