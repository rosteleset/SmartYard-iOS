//
//  PayStatusPopupViewController.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 09.09.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import TouchAreaInsets
import Lottie

class PayStatusPopupViewController: BaseViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet private weak var backgroundView: UIView!
    @IBOutlet private weak var animatedView: UIView!
    @IBOutlet private weak var headerActionLabel: UILabel!
    @IBOutlet private weak var actionLabel: UILabel!
    @IBOutlet private weak var dismissButton: BlueButton!
    @IBOutlet private weak var statusImage: UIImageView!

    @IBOutlet private weak var loadingAnimationView: LottieAnimationView!
    
    @IBOutlet private var animatedViewBottomOffset: NSLayoutConstraint!

    private var swipeDismissInteractor: SwipeInteractionController?
    
    let viewModel: PayStatusPopupViewModel
    
    init(viewModel: PayStatusPopupViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        bind()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        swipeDismissInteractor?.animatedViewBottomOffset = animatedViewBottomOffset.constant
        animatedView.roundCorners([.topLeft, .topRight], radius: 12.0)
    }
    
    private func showError(title: String?, message: String?) {
        loadingAnimationView.pause()
        loadingAnimationView.isHidden = true
        statusImage.image = UIImage(named: "PayWrong")
        statusImage.isHidden = false
        dismissButton.isHidden = false
        dismissButton.isEnabled = true
        if let title = title {
            headerActionLabel.text = title
            headerActionLabel.isHidden = false
        } else {
            headerActionLabel.isHidden = true
        }
        if let message = message {
            actionLabel.text = message
            actionLabel.isHidden = false
        } else {
            actionLabel.isHidden = true
        }
    }
    
    private func showLoader(_ message: String) {
        loadingAnimationView.play()
        
        loadingAnimationView.isHidden = false
        dismissButton.isHidden = true
        statusImage.isHidden = true
        headerActionLabel.isHidden = true
        actionLabel.isHidden = false
        actionLabel.text = message
    }
    
    private func showSuccess(title: String, message: String) {
        loadingAnimationView.pause()
        loadingAnimationView.isHidden = true
        statusImage.image = UIImage(named: "PaySuccess")
        statusImage.isHidden = false
        dismissButton.isHidden = false
        dismissButton.isEnabled = true
        headerActionLabel.text = title
        actionLabel.text = message
        headerActionLabel.isHidden = false
        actionLabel.isHidden = false
    }
    
    private func bind() {
        
        let input = PayStatusPopupViewModel.Input(
            closeButtonTapped: dismissButton.rx.tap.asDriverOnErrorJustComplete()
        )
        
        let output = viewModel.transform(input: input)
        
        output.activeState
            .drive(
                onNext: { [weak self] state in
                    switch state {
                    case let .error(title, message):
                        self?.showError(title: title, message: message)
                    case let .success(title, message):
                        self?.showSuccess(title: title, message: message)
                    case .wait:
                        self?.showLoader("Ваш платёж в обработке")
                    }
                }
            )
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx
            .notification(.reconfigureGestures)
            .asDriverOnErrorJustComplete()
            .drive(
                onNext: { [weak self] _ in
                    guard let self = self else {
                        return
                    }
                    self.configureGestures(with: 0)
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func configureView() {
        let animation = LottieAnimation.named("LoaderAnimationBlue")
        
        loadingAnimationView.animation = animation
        loadingAnimationView.loopMode = .loop
        loadingAnimationView.backgroundBehavior = .pauseAndRestore
        
        addDismissViewGesture()
        configureSwipeAction()

        showLoader("Ваш платёж в обработке")
        subscribeToPaymentsNotifications()
    }
    
    private func configureSwipeAction() {
        swipeDismissInteractor = SwipeInteractionController(
            viewController: self,
            animatedView: animatedView
        )
        
        swipeDismissInteractor?.animatedViewBottomOffset = animatedViewBottomOffset.constant
        swipeDismissInteractor?.velocityThreshold = 1500
        
        transitioningDelegate = self
    }
    
    private func subscribeToPaymentsNotifications() {
        NotificationCenter.default.rx.notification(.paymentCompleted)
            .asDriverOnErrorJustComplete()
            .drive(
                onNext: { [weak self] notification in
                    guard let self = self,
                          let userInfo = notification.userInfo,
                          let object = userInfo["object"] else {
                        return
                    }
                    print(object)
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func addDismissViewGesture() {
        let dismissViewTapGesture = UITapGestureRecognizer()
        backgroundView.addGestureRecognizer(dismissViewTapGesture)
        
        dismissViewTapGesture.rx.event
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
    
    private func configureGestures(with keyboardHeight: CGFloat) {
        view.gestureRecognizers?.removeAll()
        animatedView.gestureRecognizers?.removeAll()
        backgroundView.gestureRecognizers?.removeAll()
        
        addDismissViewGesture()
        configureSwipeAction()
    }
    
}

extension PayStatusPopupViewController: PickerAnimatable {
    
    var animatedBackgroundView: UIView { return backgroundView }
    
    var animatedMovingView: UIView { return animatedView }
    
}

extension PayStatusPopupViewController: UIViewControllerTransitioningDelegate {
    
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
