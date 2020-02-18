//
//  Animation+Fade.swift
//  SmartYard
//
//  Created by admin on 31/01/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import XCoordinator
import Cartography

extension Animation {
    
    static let fade = Animation(
        presentation: InteractiveTransitionAnimation.fadePresentation,
        dismissal: InteractiveTransitionAnimation.fadeDismissal
    )
    
}

private extension InteractiveTransitionAnimation {
    
    static let fadePresentation = InteractiveTransitionAnimation(duration: 0.25) { transitionContext in
        let containerView = transitionContext.containerView
        
        guard let toView = transitionContext.view(forKey: .to) else {
            return
        }
        
        toView.alpha = 0.0
        containerView.addSubview(toView)
        
        constrain(toView, containerView) { view, container in
            view.edges == container.edges
        }
        
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
    
    static let fadeDismissal = InteractiveTransitionAnimation(duration: 0.25) { transitionContext in
        let containerView = transitionContext.containerView
        
        guard let fromView = transitionContext.view(forKey: .from) else {
            return
        }
        
        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            options: [.curveLinear],
            animations: {
                fromView.alpha = 0
            },
            completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        )
    }
    
}
