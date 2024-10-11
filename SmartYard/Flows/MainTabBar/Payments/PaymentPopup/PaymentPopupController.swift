//
//  PaymentPopupController.swift
//  SmartYard
//
//  Created by Mad Brains on 07.04.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import PassKit
import RxSwift
import RxCocoa

class PaymentPopupController: BaseViewController {
    
    @IBOutlet private weak var successView: UIView!
    @IBOutlet private weak var contractNumberLabel: UILabel!
//    @IBOutlet private weak var payButton: UIButton!
//    @IBOutlet private weak var cardButton: UIButton!
    @IBOutlet private weak var recommendedSumLabel: UILabel!
    @IBOutlet private weak var sumTextField: UITextField!
    @IBOutlet private weak var backgroundView: UIView!
    @IBOutlet private weak var animatedView: UIView!
    @IBOutlet private weak var cardButton: BlueButton!

    @IBOutlet private weak var payResultImageView: UIImageView!
    @IBOutlet private weak var payResultTitle: UILabel!
    @IBOutlet private weak var payResultHint: UILabel!
    
    @IBOutlet private var animatedViewBottomOffset: NSLayoutConstraint!
    
    @IBAction private func cardButtonAction(sender: AnyObject) {
        if let button = sender as? BlueButton {
            button.isHidden = true
        }
    }
    
    private var swipeDismissInteractor: SwipeInteractionController?
    
    private let viewModel: PaymentPopupViewModel

//    private var payCompletion: ((PKPaymentAuthorizationResult) -> Void)?
    
    private let payTrigger = PublishSubject<(Data?, String)>()
    private let cardTrigger = PublishSubject<NSDecimalNumber>()

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
        
//        let output = viewModel.transform(input: input)

//        payButton.rx
//            .tap
//            .asDriver()
//            .drive(
//                onNext: { [weak self] in
//                    guard let self = self else {
//                        return
//                    }
// 
//                    self.sumTextField.resignFirstResponder()
//                    var paymentNetworks: [PKPaymentNetwork] = [.masterCard, .visa]
//                    
//                    if #available(iOS 14.5, *) {
//                        paymentNetworks.append(.mir)
//                    }
//                    
//                    guard PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: paymentNetworks) else {
//                        return
//                    }
//                    
//                    let request = PKPaymentRequest()
//                    request.merchantIdentifier = Constants.merchant
//                    request.countryCode = "RU"
//                    request.currencyCode = "RUB"
//                    request.supportedNetworks = paymentNetworks
//                    request.merchantCapabilities = [.capability3DS]
//                    let decimalSeparator = [NSLocale.Key.decimalSeparator: Locale.current.decimalSeparator]
//                    let amount = NSDecimalNumber(string: self.sumTextField.text, locale: decimalSeparator)
//                    
//                    // Приложение вывалится в exception если пользователь нажмёт "оплатить" с не валидным полем сумма
//                    guard amount != NSDecimalNumber.notANumber else {
//                        return
//                    }
//                    
//                    request.paymentSummaryItems = [PKPaymentSummaryItem(label: "Внести", amount: amount)]
//                    
//                    guard let authorizationViewController = PKPaymentAuthorizationViewController(paymentRequest: request) else {
//                        return
//                    }
//                    
//                    authorizationViewController.delegate = self
//                    self.present(authorizationViewController, animated: true, completion: nil)
//                }
//            )
//            .disposed(by: disposeBag)
        
//        cardButton.rx
//            .tap
//            .asDriver()
//            .drive(
//                onNext: { [weak self] in
//                    guard let self = self else {
//                        return
//                    }
//
//                    self.sumTextField.resignFirstResponder()
//
//                    let decimalSeparator = [NSLocale.Key.decimalSeparator: Locale.current.decimalSeparator]
//                    let amount = NSDecimalNumber(string: self.sumTextField.text, locale: decimalSeparator)
//
//                    // Приложение вывалится в exception если пользователь нажмёт "оплатить" с не валидным полем сумма
//                    guard amount != NSDecimalNumber.notANumber else {
//                        return
//                    }
//
//                    self.cardTrigger.onNext(amount)
//                }
//            )
//            .disposed(by: disposeBag)
        
//        let input = PaymentPopupViewModel.Input(
//            payProcess: payTrigger.asDriverOnErrorJustComplete(),
//            cardButtonTapped: cardTrigger.asDriverOnErrorJustComplete()
//        )
        
        let input = PaymentPopupViewModel.Input(
            cardButtonTapped: cardButton.rx.tap.asDriverOnErrorJustComplete(),
            inputSumNumText: sumTextField.rx.text.asDriver(onErrorJustReturn: nil)
        )

        let output = viewModel.transform(input: input)

        output.isAbleToProceed
            .drive(
                onNext: { [weak self] isAbleToProceed in
                    self?.cardButton.isEnabled = isAbleToProceed
                }
            )
            .disposed(by: disposeBag)
        
//        output.isPaySuccessTrigger
//            .drive(
//                onNext: { [weak self] isSuccess in
//                    guard let self = self, let uPayCompletion = self.payCompletion else {
//                        return
//                    }
//            
//                    self.sumTextField.isHidden = true
//                    self.successView.isHidden = false
//                    
//                    self.payResultTitle.text = isSuccess ? "Готово!" : "Ошибка!"
//                    self.payResultHint.text = isSuccess ? "Ожидайте, платёж обрабатывается" : "Оплата не прошла"
//                    
//                    let resultImageName = isSuccess ? "SuccessIcon" : "ErrorIcon"
//                    self.payResultImageView.image = UIImage(named: resultImageName)
//                    
//                    let status: PKPaymentAuthorizationStatus = isSuccess ? .success : .failure
//                    uPayCompletion(PKPaymentAuthorizationResult(status: status, errors: []))
//                }
//            )
//            .disposed(by: disposeBag)
        output.recommendedSum
            .drive(
                onNext: { [weak self] sum in
                    guard let uSum = sum else {
                        self?.recommendedSumLabel.isHidden = true
                        return
                    }
                    
                    self?.recommendedSumLabel.isHidden = false
                    self?.recommendedSumLabel.text = "Рекомендуемая - " + String(format: "%.2f", uSum)
                }
            )
            .disposed(by: disposeBag)
        
        output.contractNumber
            .drive(
                onNext: { [weak self] value in
                    guard let uValue = value else {
                        self?.contractNumberLabel.text = nil
                        return
                    }
                    
                    self?.contractNumberLabel.text = "№\(uValue)"
                }
            )
            .disposed(by: disposeBag)
        
    }
    
    private func configureView() {
        configureSwipeAction()
        configureRxKeyboard()
        view.backgroundColor = .clear
        successView.isHidden = true
        
//        if #available(iOS 14.5, *) {
//            if !PKPaymentAuthorizationController.canMakePayments(usingNetworks: [.visa, .masterCard, .mir]) {
//                payButton.removeFromSuperview()
//            }
//        } else {
//            if !PKPaymentAuthorizationController.canMakePayments(usingNetworks: [.visa, .masterCard]) {
//                payButton.removeFromSuperview()
//            }
//        }
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
                    
                    let calcOffset = keyboardHeight - textFieldBottomOffset + 2 * textFieldOffsetToButton + 2 * buttonWithOffset
                    
                    let offset = (keyboardHeight == 0) || (self.view.frame.height == keyboardHeight) ? defaultBottomOffset : calcOffset
                    
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
    
//    func processPayment(_ token: Data? = nil, completion: ((PKPaymentAuthorizationResult) -> Void)? = nil) {
//        guard let uCompletion = completion else {
//            return
//        }
//        
//        guard let amount = sumTextField.text else {
//            uCompletion(PKPaymentAuthorizationResult(status: .failure, errors: []))
//            return
//        }
//        
//        payCompletion = uCompletion
//        payTrigger.onNext((token, amount))
//    }
    
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

// extension PaymentPopupController: PKPaymentAuthorizationViewControllerDelegate {
//
//    func paymentAuthorizationViewController(
//        _ controller: PKPaymentAuthorizationViewController,
//        didAuthorizePayment payment: PKPayment,
//        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
//    ) {
//        processPayment(payment.token.paymentData, completion: completion)
//    }
//
//    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
//        controller.dismiss(animated: true, completion: nil)
//    }
//
// }
