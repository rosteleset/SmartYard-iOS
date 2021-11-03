//
//  Animation+Fade.swift
//  SmartYard
//
//  Created by admin on 31/01/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import XCoordinator
import Cartography

extension Animation {
    
    static let fade = Animation(
        presentation: InteractiveTransitionAnimation.fade,
        dismissal: InteractiveTransitionAnimation.fade
    )
    
}

extension InteractiveTransitionAnimation {
    
    static let fade = InteractiveTransitionAnimation(duration: 0.25) { transitionContext in
        let containerView = transitionContext.containerView
        
        guard let toView = transitionContext.view(forKey: .to) else {
            return
        }
        
        toView.alpha = 0.0
        
        containerView.addSubview(toView)
        
        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            options: [.curveLinear],
            animations: {
                toView.alpha = 1.0
            },
            completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        )
    }
    
}
