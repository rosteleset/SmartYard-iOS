//
//  SmartYardPaymentController.swift
//  SmartYard
//
//  Created by Mad Brains on 07.04.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit

protocol SmartYardPaymentViewDelegate: AnyObject {
    
    func payContract(sum: Double)
    
}

class SmartYardPaymentController: BaseViewController {
    
    @IBOutlet private weak var backgroundView: UIView!
    @IBOutlet private weak var animatedView: UIView!
    @IBOutlet private var animatedViewBottomOffset: NSLayoutConstraint!
    
    private var swipeDismissInteractor: SwipeInteractionController?
    
    weak var delegate: SmartYardPaymentViewDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        swipeDismissInteractor?.animatedViewBottomOffset = animatedViewBottomOffset.constant
    }
    
    private func configureView() {
        configureSwipeAction()
        view.backgroundColor = .clear
    }
    
    private func configureSwipeAction() {
        swipeDismissInteractor = SwipeInteractionController(
            viewController: self,
            animatedView: animatedView
        )
        
        swipeDismissInteractor?.animatedViewBottomOffset = animatedViewBottomOffset.constant
        swipeDismissInteractor?.velocityThreshold = 1500
        transitioningDelegate = self
        
        animatedView.layer.cornerRadius = 30
        animatedView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        let tapGesture = UITapGestureRecognizer()
        backgroundView.addGestureRecognizer(tapGesture)
        tapGesture.rx.event
            .subscribe(
                onNext: { [weak self] _ in
                    self?.dismiss(
                        animated: true,
                        completion: nil
                    )
                }
            )
            .disposed(by: disposeBag)
    }
    
    @IBAction private func payButtonDidTap(_ sender: Any) {
        delegate?.payContract(sum: 100)
        dismiss(animated: true, completion: nil)
    }
    
}

extension SmartYardPaymentController: PickerAnimatable {
    
    var animatedBackgroundView: UIView { return backgroundView }
    
    var animatedMovingView: UIView { return animatedView }
    
}

extension SmartYardPaymentController: UIViewControllerTransitioningDelegate {
    
    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
        ) -> UIViewControllerAnimatedTransitioning? {
        return PickerPresentAnimator()
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PickerDismissAnimator()
    }
    
    func interactionControllerForDismissal(
        using animator: UIViewControllerAnimatedTransitioning
        ) -> UIViewControllerInteractiveTransitioning? {
        guard let interactionInProgress = swipeDismissInteractor?.interactionInProgress else {
            return nil
        }
        return interactionInProgress ? swipeDismissInteractor : nil
    }
    
}
