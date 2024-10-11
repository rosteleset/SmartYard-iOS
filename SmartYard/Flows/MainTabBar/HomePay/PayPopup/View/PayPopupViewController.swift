//
//  PayPopupViewController.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 28.06.2024.
//  Copyright © 2024 Layka. All rights reserved.
//
// swiftlint:disable function_body_length type_body_length cyclomatic_complexity closure_body_length

import UIKit
import RxSwift
import RxCocoa
import TouchAreaInsets
import Lottie

@objc protocol PayTypeCellProtocol {
    func didTapSelectView(for cell: PaySelectTypeCell)
}

class PayPopupViewController: BaseViewController, UIGestureRecognizerDelegate {

    @IBOutlet private weak var balanceSendView: UIView!
    
    @IBOutlet private weak var contractNumberLabel: UILabel!
    @IBOutlet private weak var sumTextField: UITextField!
    @IBOutlet private weak var backgroundView: UIView!
    @IBOutlet private weak var animatedView: UIView!
    @IBOutlet private weak var cardButton: BlueButton!
    
    @IBOutlet private weak var viewSummaButtons: UIView!
    @IBOutlet private weak var preselectedSumma250: UIButton!
    @IBOutlet private weak var preselectedSumma300: UIButton!
    @IBOutlet private weak var preselectedSumma450: UIButton!
    @IBOutlet private weak var preselectedSumma650: UIButton!
    @IBOutlet private weak var preselectedSumma1000: UIButton!

    @IBOutlet private weak var payTypesCollectionView: UICollectionView!
    @IBOutlet private weak var saveCardContainerView: UIView!
    @IBOutlet private weak var saveCardSwitch: UISwitch!
    
    @IBOutlet private weak var autopayContainerView: UIView!
    @IBOutlet private weak var autopaySwitch: UISwitch!
    
    @IBOutlet private weak var checkBoxView: UIView!
    @IBOutlet private weak var checkEmailContainerView: UIView!
    @IBOutlet private weak var checkEmailSwitch: UISwitch!
    @IBOutlet private weak var emailTextField: UITextField!
    
    @IBOutlet private weak var agreementTextView: UITextView!

    @IBOutlet private var animatedViewBottomOffset: NSLayoutConstraint!
    @IBOutlet private var animatedViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var contractNumberHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var summaHeaderHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var summaButtonsHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var payTypesHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var checkHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var skeletonView: UIView!
    @IBOutlet private weak var loadingAnimationView: LottieAnimationView!

    @IBAction private func cardButtonAction(sender: AnyObject) {
        if let button = sender as? BlueButton {
            button.isHidden = true
        }
    }
    
    @IBAction private func summaAction(sender: UIButton) {
        sumTextField.clear()
        switch sender {
        case preselectedSumma250:
            sumTextField.insertText("250")
        case preselectedSumma300:
            sumTextField.insertText("300")
        case preselectedSumma450:
            sumTextField.insertText("450")
        case preselectedSumma650:
            sumTextField.insertText("650")
        case preselectedSumma1000:
            sumTextField.insertText("1000")
        default:
            break
        }
    }
    
    private var swipeDismissInteractor: SwipeInteractionController?
    
    private var payTypes = [PayTypeObject]()
    let viewModel: PayPopupViewModel

    private let payTrigger = PublishSubject<(Data?, String)>()
    private let cardTrigger = PublishSubject<NSDecimalNumber>()
    private let payTypeTrigger = PublishSubject<PayTypeObject?>()
    private let cardEditSettingsTrigger = PublishSubject<CGFloat?>()
    private let activeTextFieldTrigger = PublishSubject<UITextField?>()
    private let animatedHeightSubject = BehaviorSubject<CGFloat>(value: 780)
    private let tbankErrorTrigger = PublishSubject<(String, String?)>()
    
    private let currentPayState = BehaviorSubject<PayStepState?>(value: .inputbalance)
    private var selectedNumberOfPayType: Int?
    private var animatedHeight: CGFloat = 780
    private var animatedHeightState: PayPopupHeightState = .large
    
    private let saveCardTapGesture = UITapGestureRecognizer()
    private let autopayTapGesture = UITapGestureRecognizer()
    private let checkEmailTapGesture = UITapGestureRecognizer()
    
    private let limitDocShowTrigger = PublishSubject<String>()
    private let serviceDocShowTrigger = PublishSubject<String>()

    init(viewModel: PayPopupViewModel) {
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
        configureCollectionView()
        bind()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        swipeDismissInteractor?.animatedViewBottomOffset = animatedViewBottomOffset.constant
        animatedView.roundCorners([.topLeft, .topRight], radius: 12.0)
    }
    
    private func bind() {
        
        let input = PayPopupViewModel.Input(
            inputSumNumText: sumTextField.rx.text.asDriver(onErrorJustReturn: nil),
            inputEmailText: emailTextField.rx.text.asDriver(onErrorJustReturn: nil),
            saveCardTrigger: saveCardTapGesture.rx.event.asDriver().mapToVoid(),
            autopayTrigger: autopayTapGesture.rx.event.asDriver().mapToVoid(),
            checkEmailTrigger: checkEmailTapGesture.rx.event.asDriver().mapToVoid(),
            cardEditSettingsTrigger: cardEditSettingsTrigger.asDriver(onErrorJustReturn: nil),
            cardButtonTapped: cardButton.rx.tap.asDriverOnErrorJustComplete(),
            animatedHeight: animatedHeightSubject.asDriverOnErrorJustComplete(),
            limitDocShowTrigger: limitDocShowTrigger.asDriverOnErrorJustComplete(),
            serviceDocShowTrigger: serviceDocShowTrigger.asDriverOnErrorJustComplete(),
            vc: self
        )

        let output = viewModel.transform(input: input)

        output.isAbleToProceedRequest
            .drive(
                onNext: { [weak self] isAbleToProceed in
                    self?.cardButton.isEnabled = isAbleToProceed
                }
            )
            .disposed(by: disposeBag)
        
        output.isPaymentActive
            .drive(
                onNext: { [weak self] isPaymentActive in
                    self?.cardButton.isHidden = isPaymentActive
                }
            )
        
        output.recommendedSum
            .drive(
                onNext: { [weak self] sum in
                    guard let self = self, let uSum = sum else {
                        self?.sumTextField.text = "0"
                        return
                    }
                    self.sumTextField.text = String(format: "%.0f", uSum)
                    self.sumTextField.sendActions(for: .valueChanged)
                }
            )
            .disposed(by: disposeBag)
        
        output.savedEmail
            .drive(
                onNext: { [weak self] email in
                    guard let email = email else {
                        self?.emailTextField.insertText("")
                        return
                    }
                    self?.sumTextField.insertText(email)
                }
            )
            .disposed(by: disposeBag)
        
        output.isSaveCardEnable
            .withLatestFrom(output.isAutopayEnable.asDriver(onErrorJustReturn: false)) { ($0, $1) }
            .drive(
                onNext: { [weak self] state, autopay in
                    guard let state = state else {
                        self?.saveCardContainerView.isHidden = true
                        self?.autopaySwitch.isEnabled = true
                        return
                    }
                    self?.saveCardContainerView.isHidden = false
                    self?.saveCardSwitch.setOn(state, animated: true)
                    self?.autopaySwitch.isEnabled = state
                    if !state {
                        self?.autopaySwitch.isOn = false
                    } else {
                        self?.autopaySwitch.isOn = autopay
                    }
                }
            )
            .disposed(by: disposeBag)
        
        output.isAutopayEnable
            .drive(
                onNext: { [weak self] state in
                    self?.autopaySwitch.setOn(state, animated: true)
                }
            )
            .disposed(by: disposeBag)
        
        output.isCheckEmailEnable
            .drive(
                onNext: { [weak self] state in
                    self?.checkEmailSwitch.setOn(state, animated: true)
                    self?.emailTextField.isEnabled = state
                }
            )
            .disposed(by: disposeBag)

        output.payTypes
            .drive(
                onNext: { [weak self] payTypes in
                    guard let self = self else {
                        return
                    }
                    self.setPayTypes(payTypes)
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
        
        output.isCardLoaded
            .debounce(.milliseconds(25))
            .drive(
                onNext: { [weak self] isLoading in
                    self?.updateCardLoader(isEnabled: isLoading)
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
    
    private func setPayTypes(_ payTypes: [PayTypeObject]) {
        self.payTypes = payTypes
        
        payTypesCollectionView.reloadData()
    }
    
    private func updateCardLoader(isEnabled: Bool) {
        skeletonView.isHidden = !isEnabled
        if isEnabled {
            loadingAnimationView.play()
        } else {
            loadingAnimationView.pause()
        }
    }
    
    private func configureView() {
        
        let animation = LottieAnimation.named("LoaderAnimationGrey")
        
        loadingAnimationView.animation = animation
        loadingAnimationView.loopMode = .loop
        loadingAnimationView.backgroundBehavior = .pauseAndRestore
        loadingAnimationView.play()

        configureSwipeAction()
        addDismissViewGesture()
        configureRxKeyboard()
        
        view.backgroundColor = .clear
        
        saveCardContainerView.addGestureRecognizer(saveCardTapGesture)
        saveCardSwitch.isUserInteractionEnabled = false
        autopayContainerView.addGestureRecognizer(autopayTapGesture)
        autopaySwitch.isUserInteractionEnabled = false
        checkEmailContainerView.addGestureRecognizer(checkEmailTapGesture)
        checkEmailSwitch.isUserInteractionEnabled = false

        let text = "Нажимая 'Оплатить' вы соглашаетесь с лимитами и принимаете условия услуги"
        let linkLimit = "лимитами"
        let linkTerms = "условия услуги"
        let linkLimitRange = (text as NSString).range(of: linkLimit)
        let linkTermsRange = (text as NSString).range(of: linkTerms)
        
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.lightGray,
            .font: UIFont.SourceSansPro.regular(size: 14),
            .paragraphStyle: {
                let paragraph = NSMutableParagraphStyle()
                paragraph.alignment = .left
                return paragraph
            }()
        ]
        let linkLimitAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.SmartYard.blue,
            .limitAction: "p"
        ]
        let linkTermsAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.SmartYard.blue,
            .termsAction: "p"
        ]
        
        let attributedString = NSMutableAttributedString(string: text, attributes: attributes)
        attributedString.addAttributes(linkLimitAttributes, range: linkLimitRange)
        attributedString.addAttributes(linkTermsAttributes, range: linkTermsRange)
        agreementTextView.attributedText = attributedString
        agreementTextView.translatesAutoresizingMaskIntoConstraints = false
        agreementTextView.isUserInteractionEnabled = true
        
        let textTap = UITapGestureRecognizer(target: self, action: #selector(textHandleTap))
        textTap.delegate = self
        agreementTextView.addGestureRecognizer(textTap)
        
        animatedHeight = {
            guard UIScreen.main.bounds.height < 700 else {
                if UIScreen.main.bounds.height < 800 {
                    contractNumberLabel.isHidden = true
                    contractNumberHeightConstraint.constant = 0
                    animatedHeightState = .middle
                    return UIScreen.main.bounds.height
                }
                animatedHeightState = UIScreen.main.bounds.height < 900 ? .large : .big
                return 780
            }
            viewSummaButtons.isHidden = true
            contractNumberLabel.isHidden = true
            contractNumberHeightConstraint.constant = 0
            summaButtonsHeightConstraint.constant = 0
            guard UIScreen.main.bounds.height < 600 else {
                animatedHeightState = .small
                return UIScreen.main.bounds.height + 12
            }
            animatedHeightState = .verysmall
            checkBoxView.isHidden = true
            checkHeightConstraint.constant = 0
            return UIScreen.main.bounds.height + 12
        }()
//        print(UIScreen.main.bounds.height, animatedHeightState, animatedHeight)
        animatedViewHeightConstraint.constant = animatedHeight
        animatedHeightSubject.onNext(animatedHeight)
    }
    
    @objc func textHandleTap(_ sender: UITapGestureRecognizer) {
        guard let textView = sender.view as? UITextView else {
            return
        }
        let layoutManager = textView.layoutManager
        
        var location = sender.location(in: textView)
        location.x -= textView.textContainerInset.left
        location.y -= textView.textContainerInset.top
        
        let characterIndex = layoutManager.characterIndex(for: location, in: textView.textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        
        if characterIndex < textView.textStorage.length {
            let range = NSRange(location: characterIndex, length: 1)
            let substring = (textView.attributedText.string as NSString).substring(with: range)
            
            let attributeLimit = NSAttributedString.Key.limitAction
            let attributeTerms = NSAttributedString.Key.termsAction
            
            let valueLimit = textView.attributedText?.attribute(attributeLimit, at: characterIndex, effectiveRange: nil)
            let valueTerms = textView.attributedText?.attribute(attributeTerms, at: characterIndex, effectiveRange: nil)
            
            if let value = valueLimit as? String {
                limitDocShowTrigger.onNext(value)
            }
            if let value = valueTerms as? String {
                serviceDocShowTrigger.onNext(value)
            }
        }
    }
    
    private func configureCollectionView() {
        payTypesCollectionView.delegate = self
        payTypesCollectionView.dataSource = self
        
        payTypesCollectionView.register(nibWithCellClass: PayTypeViewCell.self)
        payTypesCollectionView.register(nibWithCellClass: PaySelectTypeCell.self)
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
        let dismissKeyboardTapGesture = UITapGestureRecognizer()
        dismissKeyboardTapGesture.cancelsTouchesInView = false
        animatedView.addGestureRecognizer(dismissKeyboardTapGesture)

        dismissKeyboardTapGesture.rx.event
            .subscribe(
                onNext: { [weak self] _ in
                    self?.sumTextField.resignFirstResponder()
                    self?.emailTextField.resignFirstResponder()
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
        sumTextField.delegate = self
        emailTextField.delegate = self
        
        RxKeyboard.instance.visibleHeight
            .withLatestFrom(activeTextFieldTrigger.asDriver(onErrorJustReturn: nil)) { ($0, $1) }
            .drive(
                onNext: { [weak self] args in
                    let (keyboardHeight, currentField) = args
                    
                    guard let self = self, let currentField = currentField else {
                        return
                    }

                    self.configureGestures(with: keyboardHeight)
                    let defaultBottomOffset: CGFloat = -50

                    var textFieldBottomOffset: CGFloat {
                        switch currentField {
                        case sumTextField:
                            return 340
                        case emailTextField:
                            return 180
                        default:
                            return 0
                        }
                    }
                    
                    let calcOffset = keyboardHeight - textFieldBottomOffset > defaultBottomOffset ? keyboardHeight - textFieldBottomOffset : defaultBottomOffset

                    var direction: Bool {
                        return (keyboardHeight == 0) || (self.view.frame.height == keyboardHeight)
                    }
                    let offset = direction ? defaultBottomOffset : calcOffset
                    var animatedHeight: CGFloat {
                        if direction {
                            return self.animatedHeight
                        } else {
                            if offset + self.animatedHeight > UIScreen.main.bounds.height - view.safeAreaInsets.top {
                                return UIScreen.main.bounds.height - offset - view.safeAreaInsets.top
                            }
                            return self.animatedHeight
                        }
                    }

                    UIView.animate(
                        withDuration: 0.05,
                        animations: { [weak self] in
                            guard let self = self else {
                                return
                            }
                            self.animatedViewBottomOffset.constant = offset
                            self.animatedViewHeightConstraint.constant = animatedHeight
                            if direction {
                                switch self.animatedHeightState {
                                case .big, .verysmall:
                                    break
                                case .large:
                                    if currentField == emailTextField {
                                        self.contractNumberHeightConstraint.constant = 26
                                        self.summaButtonsHeightConstraint.constant = 26
                                        self.summaHeaderHeightConstraint.constant = 26
                                    }
                                case .middle:
                                    if currentField == emailTextField {
                                        self.summaButtonsHeightConstraint.constant = 26
                                        self.summaHeaderHeightConstraint.constant = 26
                                    }
                                case .small:
                                    if currentField == emailTextField {
                                        self.payTypesHeightConstraint.constant = 138
                                    }
                                }
                            } else {
                                switch self.animatedHeightState {
                                case .big, .verysmall:
                                    break
                                case .large:
                                    if currentField == emailTextField {
                                        self.contractNumberHeightConstraint.constant = 0
                                        self.summaButtonsHeightConstraint.constant = 0
                                        self.summaHeaderHeightConstraint.constant = 0
                                    } else {
                                        self.contractNumberHeightConstraint.constant = 26
                                        self.summaButtonsHeightConstraint.constant = 26
                                        self.summaHeaderHeightConstraint.constant = 26
                                    }
                                case .middle:
                                    if currentField == emailTextField {
                                        self.summaButtonsHeightConstraint.constant = 0
                                        self.summaHeaderHeightConstraint.constant = 0
                                    } else {
                                        self.summaButtonsHeightConstraint.constant = 26
                                        self.summaHeaderHeightConstraint.constant = 26
                                    }
                                case .small:
                                    if currentField == emailTextField {
                                        self.payTypesHeightConstraint.constant = 0
                                    } else {
                                        self.payTypesHeightConstraint.constant = 138
                                    }
                                }
                            }
                            self.view.layoutIfNeeded()
                        }
                    )
                }
            )
            .disposed(by: disposeBag)
    }
    
}

extension NSAttributedString.Key {
    static let limitAction = NSAttributedString.Key(rawValue: "limitView")
    static let termsAction = NSAttributedString.Key(rawValue: "termsView")
}

extension PayPopupViewController: PayTypeCellProtocol {
    func didTapSelectView(for cell: PaySelectTypeCell) {
        cardEditSettingsTrigger.onNext(animatedViewHeightConstraint.constant - 50)
    }
}

extension PayPopupViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeTextFieldTrigger.onNext(textField)
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        activeTextFieldTrigger.onNext(nil)
    }
}

extension PayPopupViewController: UICollectionViewDelegate {
    
}

extension PayPopupViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row == 0 {
            let cell = collectionView.dequeueReusableCell(withClass: PayTypeViewCell.self, for: indexPath)
            guard let payType = (payTypes.first { $0.isSelected == true }) else {
                return cell
            }
            cell.configureCell(payType: payType)
            
            return cell
        }
        let cell = collectionView.dequeueReusableCell(withClass: PaySelectTypeCell.self, for: indexPath)
        cell.delegate = self

        return cell
    }
}

extension PayPopupViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if indexPath.row == 1 {
            return CGSize(width: collectionView.layer.bounds.width, height: 46)
        }
        return CGSize(width: collectionView.layer.bounds.width, height: 54)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
}

extension PayPopupViewController: PickerAnimatable {
    
    var animatedBackgroundView: UIView { return backgroundView }
    
    var animatedMovingView: UIView { return animatedView }
    
}

extension PayPopupViewController: UIViewControllerTransitioningDelegate {
    
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
// swiftlint:enable function_body_length type_body_length cyclomatic_complexity closure_body_length
