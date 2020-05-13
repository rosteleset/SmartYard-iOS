//
//  PaymentPopupController.swift
//  SmartYard
//
//  Created by Mad Brains on 07.04.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import PassKit
import RxSwift
import RxCocoa

class PaymentPopupController: BaseViewController {
    
    @IBOutlet private weak var successView: UIView!
    @IBOutlet private weak var allPaymentMethodButton: UIButton!
    @IBOutlet private weak var payButton: UIButton!
    @IBOutlet private weak var recommendedSumLabel: UILabel!
    @IBOutlet private weak var sumTextField: UITextField!
    @IBOutlet private weak var backgroundView: UIView!
    @IBOutlet private weak var animatedView: UIView!
    
    @IBOutlet private var animatedViewBottomOffset: NSLayoutConstraint!
    
    private var swipeDismissInteractor: SwipeInteractionController?
    
    private var paymentRequest: PKPaymentRequest = {
        let request = PKPaymentRequest()
        request.merchantIdentifier = "merchant.ru.lanta-net.pays"
        request.supportedNetworks = [.visa, .masterCard]
        request.supportedCountries = ["RU"]
        request.merchantCapabilities = .capability3DS
        request.countryCode = Locale.current.regionCode ?? "RUS"
        request.currencyCode = "RUB"
        request.paymentSummaryItems = [PKPaymentSummaryItem(label: "Ланта", amount: 1)]
        return request
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        bind()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        swipeDismissInteractor?.animatedViewBottomOffset = animatedViewBottomOffset.constant
    }
    
    private func bind() {
        payButton.rx
            .tap
            .asDriver()
            .drive(
                onNext: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    
                    // TODO: нужна будет обработка
                    self.sumTextField.resignFirstResponder()
//                    self?.sumTextField.isHidden = true
//                    self?.successView.isHidden = false
                    if let controller = PKPaymentAuthorizationViewController(paymentRequest: self.paymentRequest) {
                        controller.delegate = self
                        self.present(controller, animated: true, completion: nil)
                    }
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func configureView() {
        configureSwipeAction()
        configureRxKeyboard()
        view.backgroundColor = .clear
        successView.isHidden = true
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
    
    private func addDismissKeyboardByTapGesture() {
        let dismissKeyobardTapGesture = UITapGestureRecognizer()
        animatedView.addGestureRecognizer(dismissKeyobardTapGesture)

        dismissKeyobardTapGesture.rx.event
            .subscribe(
                onNext: { [weak self] _ in
                    self?.sumTextField.resignFirstResponder()
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func addDismissKeyboardBySwipeGesture() {
        let swipeDown = UISwipeGestureRecognizer()
        swipeDown.direction = .down
        animatedView.addGestureRecognizer(swipeDown)
        
        swipeDown.rx.event
            .subscribe(
                onNext: { [weak self] _ in
                    self?.sumTextField.resignFirstResponder()
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
        
        switch keyboardHeight {
        case 0:
            self.addDismissViewGesture()
            self.addDismissKeyboardByTapGesture()
            self.configureSwipeAction()
        default:
            self.addDismissKeyboardByTapGesture()
            self.addDismissKeyboardBySwipeGesture()
        }
    }
    
    private func configureRxKeyboard() {
        RxKeyboard.instance.visibleHeight
            .drive(
                onNext: { [weak self] keyboardHeight in
                    guard let self = self else {
                        return
                    }

                    self.configureGestures(with: keyboardHeight)
                    
                    let textFieldBottomOffset: CGFloat = 245
                    let defaultBottomOffset: CGFloat = -50
                    let textFieldOffsetToButton: CGFloat = 20
                    let buttonWithOffset: CGFloat = 65
                    
                    let calcOffset = keyboardHeight - textFieldBottomOffset + textFieldOffsetToButton + buttonWithOffset
                    
                    let offset = keyboardHeight == 0 ? defaultBottomOffset : calcOffset
                    
                    UIView.animate(
                        withDuration: 0.05,
                        animations: { [weak self] in
                            self?.animatedViewBottomOffset.constant = offset
                            self?.view.layoutIfNeeded()
                        }
                    )
                }
            )
            .disposed(by: disposeBag)
    }
    
}

extension PaymentPopupController: PickerAnimatable {
    
    var animatedBackgroundView: UIView { return backgroundView }
    
    var animatedMovingView: UIView { return animatedView }
    
}

extension PaymentPopupController: UIViewControllerTransitioningDelegate {
    
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

extension PaymentPopupController: PKPaymentAuthorizationViewControllerDelegate {
 
    func paymentAuthorizationViewController(
        _ controller: PKPaymentAuthorizationViewController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
        completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
    }
 
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
 
}
