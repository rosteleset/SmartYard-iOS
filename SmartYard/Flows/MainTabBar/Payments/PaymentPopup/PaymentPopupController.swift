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
    
    private let viewModel: PaymentPopupViewModel

    private var payCompletion: ((PKPaymentAuthorizationResult) -> Void)?
    
    private let payTrigger = PublishSubject<(Data?, String)>()

    init(viewModel: PaymentPopupViewModel) {
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
 
                    self.sumTextField.resignFirstResponder()
                    let paymentNetworks: [PKPaymentNetwork] = [.masterCard, .visa]
                    
                    if PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: paymentNetworks) {
                        let request = PKPaymentRequest()
                        request.merchantIdentifier = "merchant.ru.lanta-net.pays"
                        request.countryCode = "RU"
                        request.currencyCode = "RUB"
                        request.supportedNetworks = paymentNetworks
                        request.merchantCapabilities = [.capability3DS]
                        
                        let decimalSeparator = [NSLocale.Key.decimalSeparator: Locale.current.decimalSeparator]
                        let amount = NSDecimalNumber(string: self.sumTextField.text, locale: decimalSeparator)
                        
                        request.paymentSummaryItems = [PKPaymentSummaryItem(label: "Ланта", amount: amount)]
                        
                        let authorizationViewController = PKPaymentAuthorizationViewController(paymentRequest: request)
                        
                        if let controller = authorizationViewController {
                            controller.delegate = self
                            self.present(controller, animated: true, completion: nil)
                        }
                    }
                }
            )
            .disposed(by: disposeBag)
        
        let input = PaymentPopupViewModel.Input(
            payProcess: payTrigger.asDriverOnErrorJustComplete()
        )
        
        let output = viewModel.transform(input)
        
        output.isPaySuccessTrigger
            .drive(
                onNext: { [weak self] isSuccess in
                    guard let self = self, let uPayCompletion = self.payCompletion else {
                        return
                    }
                    
                    let status: PKPaymentAuthorizationStatus = isSuccess ? .success : .failure
                    uPayCompletion(PKPaymentAuthorizationResult(status: status, errors: []))
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
    
    func processPayment(_ token: Data? = nil, completion: ((PKPaymentAuthorizationResult) -> Void)? = nil) {
        print("here")
        guard let uCompletion = completion else {
            print("11111111")
            return
        }
        print("2222222")
        guard let amount = sumTextField.text else {
            print("333333333")
           // uCompletion(PKPaymentAuthorizationResult(status: .failure, errors: []))
            return
        }
        
        payCompletion = uCompletion
        payTrigger.onNext((token, amount))
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
        processPayment(payment.token.paymentData, completion: completion)
    }
 
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        controller.dismiss(animated: true, completion: nil)
        sumTextField.isHidden = true
        successView.isHidden = false
    }
 
}
