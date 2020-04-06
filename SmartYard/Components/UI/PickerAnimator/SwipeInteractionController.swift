import Foundation
import UIKit

class SwipeInteractionController: UIPercentDrivenInteractiveTransition {
    
    // MARK: Для закрытия окна нужно сделать свайп вниз. Необходимая длина свайпа рассчитывается по формуле:
    // translation == animatedView.height - animatedViewBottomOffset - translationDecreaseConstant
    
    private(set) var interactionInProgress = false
    
    private var shouldCompleteTransition = false
    
    private weak var viewController: UIViewController?
    
    /// Показывает, на сколько пикселей animatedView.bottom находится ниже superview.bottom
    var animatedViewBottomOffset: CGFloat = 0

    /// Уменьшает необходимый для закрытия окна translation на фиксированное значение
    var translationDecreaseConstant: CGFloat = 0
    
    /// Устанавливает порог максимальной скорости свайпа, после которого вьюха будет автоматически закрываться
    var velocityThreshold: CGFloat?
    
    init(viewController: UIViewController, animatedView: UIView) {
        super.init()
        
        self.viewController = viewController
        
        animatedView.addGestureRecognizer(
            UIPanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        )
    }
    
    @objc private func handleGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard let animatedViewHeight = gestureRecognizer.view?.bounds.height,
            let transitionView = gestureRecognizer.view?.superview?.superview else {
            finish()
            return
        }
        
        let currentTranslation = gestureRecognizer.translation(in: transitionView).y
        let currentVelocity = gestureRecognizer.velocity(in: transitionView).y
        let requiredTranslation = animatedViewHeight - animatedViewBottomOffset - translationDecreaseConstant
        let progress = min(max(currentTranslation / requiredTranslation, 0.0), 1.0)
        
        switch gestureRecognizer.state {
        case .began:
            interactionInProgress = true
            viewController?.dismiss(animated: true, completion: nil)
        case .changed:
            let didPassVelocityThreshold = currentVelocity > velocityThreshold ?? CGFloat.greatestFiniteMagnitude
            shouldCompleteTransition = progress > 0.5 || didPassVelocityThreshold
            update(progress)
        case .cancelled:
            interactionInProgress = false
            cancel()
        case .ended:
            interactionInProgress = false
            if shouldCompleteTransition {
                finish()
            } else {
                cancel()
            }
        default: break
        }
    }
    
}
