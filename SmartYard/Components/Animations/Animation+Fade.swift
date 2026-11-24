//
//  Animation+Fade.swift
//  SmartYard
//
//  Created by admin on 31/01/2020.
//  Copyright © 2021 Sesameware. All rights reserved.
//

import UIKit
import XCoordinator
import Cartography

extension Animation {
    
    static let fade = Animation(
        presentation: InteractiveTransitionAnimation.fade,
        dismissal: InteractiveTransitionAnimation.fade
    )

    static let authenticationFade = Animation(
        presentation: InteractiveTransitionAnimation.authenticationFade,
        dismissal: InteractiveTransitionAnimation.authenticationFade
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

    static let authenticationFade = InteractiveTransitionAnimation(duration: 0.25) { transitionContext in
        guard let toView = transitionContext.view(forKey: .to),
              let toController = transitionContext.viewController(forKey: .to) else {
            transitionContext.completeTransition(false)
            return
        }

        let container = transitionContext.containerView
        toView.frame = transitionContext.finalFrame(for: toController)
        toView.isHidden = true
        container.addSubview(toView)
        toView.layoutIfNeeded()

        // Cross-dissolve the composed screens so the background cannot show through separate hosting layers.
        UIView.transition(
            with: container,
            duration: 0.25,
            options: [.transitionCrossDissolve, .curveLinear],
            animations: {
                toView.isHidden = false
            },
            completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        )
    }
    
}
