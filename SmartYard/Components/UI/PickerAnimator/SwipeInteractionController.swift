import Foundation
import UIKit

final class SwipeInteractionController: UIPercentDrivenInteractiveTransition {
    
    // MARK: Для закрытия окна нужно сделать свайп вниз. Необходимая длина свайпа рассчитывается по формуле:
    // translation == animatedView.height - animatedViewBottomOffset - translationDecreaseConstant
    
    private(set) var interactionInProgress = false
    
    private var shouldCompleteTransition = false
    
    private weak var viewController: UIViewController?
    
    private weak var scrollView: UIScrollView?
    
    private var initialOffset: CGPoint = .zero
    
    /// Показывает, на сколько пикселей animatedView.bottom находится ниже superview.bottom
    var animatedViewBottomOffset: CGFloat = 0

    /// Уменьшает необходимый для закрытия окна translation на фиксированное значение
    var translationDecreaseConstant: CGFloat = 0
    
    /// Устанавливает порог максимальной скорости свайпа, после которого вьюха будет автоматически закрываться
    var velocityThreshold: CGFloat?
    
    init(viewController: UIViewController, animatedView: UIView, scrollView: UIScrollView? = nil) {
        super.init()
        
        self.viewController = viewController
        self.scrollView = scrollView
        
        animatedView.addGestureRecognizer(
            UIPanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        )
        
        scrollView?.panGestureRecognizer.addTarget(self, action: #selector(handleScrollViewGestureRecognizer(_:)))
    }
    
    @objc private func handleScrollViewGestureRecognizer(_ gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            // сохраняем смещение контента в скролл-вью в момент начала жеста
            initialOffset = scrollView?.contentOffset ?? .zero
            // пробрасываем жест для обработчика родительского вью
            handleGesture(gestureRecognizer)
        case .changed:
            // если скролл-вью не на верхней точке, то дальше не пробрасываем обработку жеста, тем самым
            // даём возможность работать только стандартному обработчику scrollView.
            // Но если мы уже на верхней точке в скролл-вью, то мы также пробрасываем событие жеста
            // для родительской вьюхи.
            if scrollView?.contentOffset.y == 0 {
                // сохраняем состояние смещения.
                let originalTranslation = gestureRecognizer.translation(in: scrollView)
                
                // модифицируем смещение с учётом initialOffset (смещения скролл-вью в начале жеста),
                // чтобы родительская вьюха получила только часть смещения, без учёта "пробега" от скрола.
                gestureRecognizer.setTranslation(
                    originalTranslation.applying(
                        CGAffineTransform(translationX: -initialOffset.x, y: -initialOffset.y)
                    ),
                    in: scrollView
                )
                /* gestureRecognizer.setTranslation(
                    CGPoint(x: originalTranslation.x - initialOffset.x, y: originalTranslation.y - initialOffset.y),
                    in: scrollView
                )
                */
                
                // обрабатываем смещение родительской вьюхой.
                handleGesture(gestureRecognizer)
                
                // восстанавливаем исходное состояние смещения для корректной работы скролл-вью
                gestureRecognizer.setTranslation(originalTranslation, in: scrollView)
            }
        case .ended, .cancelled:
            handleGesture(gestureRecognizer)
        default: break
        }
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
