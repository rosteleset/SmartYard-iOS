import Foundation
import UIKit

protocol PickerAnimatable {
    
    var animatedBackgroundView: UIView { get }
    var animatedMovingView: UIView { get }
    
}

class PickerPresentAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toVC = transitionContext.viewController(forKey: .to),
              let backgroundView = (toVC as? PickerAnimatable)?.animatedBackgroundView,
              let movingView = (toVC as? PickerAnimatable)?.animatedMovingView
        else {
            return
        }
        
        transitionContext.containerView.addSubview(toVC.view)
        let finalFrame = transitionContext.finalFrame(for: toVC)
        toVC.view.frame = finalFrame
        toVC.view.setNeedsLayout()
        toVC.view.layoutIfNeeded()
        
        backgroundView.alpha = 0
        let originalFrame = movingView.frame
        var movingFrame = originalFrame
        movingFrame.origin.y = finalFrame.maxY
        movingView.frame = movingFrame
        
        let duration = self.transitionDuration(using: transitionContext)
        UIView.animate(
            withDuration: duration / 2,
            animations: {
                backgroundView.alpha = 1
            }
        )
        
        UIView.animate(
            withDuration: duration,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0.0,
            options: [],
            animations: {
                movingView.frame = originalFrame
            },
            completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        )
    }
    
}
