//
//  NavigationTransitions.swift
//  SmartYard
//
//  Created by admin on 17/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import XCoordinator

extension NavigationTransition {
    
    // multiple(dismiss + set) не работает в iOS 12. Какой-то баг с дисмиссом. Пришлось закостылить
    static func dismissAllAndSet(_ presentable: Presentable) -> Transition {
        return Transition(presentables: [], animationInUse: nil) { nc, _, _ in
            guard nc.presentedViewController != nil else {
                nc.setViewControllers([presentable.viewController], animated: true)
                return
            }
            
            nc.dismiss(animated: true) { [weak nc] in
                nc?.setViewControllers([presentable.viewController], animated: true)
            }
        }
    }
    
}
