//
//  UserNameViewController.swift
//  SmartYard
//
//  Created by admin on 05/02/2020.
//  Copyright © 2021 Sesameware. All rights reserved.
//

import UIKit
import JGProgressHUD
import RxCocoa
import RxRelay
import RxSwift

final class UserNameViewController: BaseViewController, LoaderPresentable {

    @IBOutlet private weak var nameTextField: SmartYardBorderedTextField!
    @IBOutlet private weak var middleNameTextField: SmartYardBorderedTextField!
    @IBOutlet private weak var continueButton: UIButton!
    @IBOutlet private weak var agreementContainerView: UIView!
    @IBOutlet private weak var agreementCheckBoxView: SmartYardCheckBoxView!
    @IBOutlet private weak var agreementTextView: UITextView!
    
    @IBOutlet private var mainContainerBottomConstraint: NSLayoutConstraint!
    @IBOutlet private var continueButtonAgreementTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var titleLabel: UILabel!
    private let viewModel: UserNameViewModel
    private let preloadedName: APIClientName?
    private let agreementAcceptedRelay = BehaviorRelay<Bool>(value: false)
    private let legalDocumentTrigger = PublishSubject<URL>()
    private lazy var continueButtonCompactTopConstraint = continueButton.topAnchor.constraint(
        equalTo: middleNameTextField.bottomAnchor,
        constant: 24
    )
    private let agreementLinkColor = UIColor.SmartYard.blue
    private var isAgreementAccepted = false {
        didSet {
            agreementAcceptedRelay.accept(isAgreementAccepted)
            updateAgreementCheckBoxAppearance()
        }
    }
    
    var loader: JGProgressHUD?
    
    init(viewModel: UserNameViewModel, preloadedName: APIClientName?) {
        self.viewModel = viewModel
        self.preloadedName = preloadedName
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupConstraints()
        configureUI()
        configureRxKeyboard()
        bind()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        view.isUserInteractionEnabled = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateAgreementCheckBoxAppearance()
    }
    
    private func setupConstraints() {
        let agreementStackView = UIStackView.horizontal(spacing: 10, alignment: .center)
        agreementStackView.add {
            agreementCheckBoxView!
            agreementTextView!
        }
        agreementContainerView.pinSubview(agreementStackView)
    }

    private func configureUI() {
        titleLabel.text = L10n.Auth.UserName.howCanICallYou
        continueButton.setTitle(L10n.Common.next, for: .normal)
        let gesture = UITapGestureRecognizer()
        gesture.cancelsTouchesInView = false
        view.addGestureRecognizer(gesture)

        let serverPattern = AccessService.shared.nameValidationPattern
        let validators = (
            first: ValidatorFactory.makeFirst(from: serverPattern),
            last: ValidatorFactory.makeLast(from: serverPattern),
            patronymic: ValidatorFactory.makePatronymic(from: serverPattern)
        )

        configureAgreementView()

        gesture.rx.event.asDriver()
            .drive(
                onNext: { [weak self] _ in
                    self?.view.endEditing(true)
                }
            )
            .disposed(by: disposeBag)
        
        nameTextField.setPlaceholder(string: L10n.Profile.firstName, isRequiredField: true)
        nameTextField.delegate = self
        nameTextField.text = preloadedName?.name
        nameTextField.sendActions(for: .allEditingEvents)
        nameTextField.configure(with: validators.first)
        nameTextField.updateValidationAppearance()

        middleNameTextField.setPlaceholder(string: L10n.Profile.patronymic)
        middleNameTextField.delegate = self
        middleNameTextField.text = preloadedName?.patronymic
        middleNameTextField.sendActions(for: .allEditingEvents)
        middleNameTextField.configure(with: validators.patronymic)
        middleNameTextField.updateValidationAppearance()
    }
    
    private func configureRxKeyboard() {
        // MARK: Здесь был пролаг (не было анимации) если экран был первым при запуске приложения
        // Пришлось закастомить RxKeyboard и проксировать параметры анимации, чтобы точно восстановить их
        
        RxKeyboard.instance.visibleHeight
            .debounce(.milliseconds(50))
            .withLatestFrom(RxKeyboard.instance.curve.asDriver(onErrorJustReturn: nil)) { ($0, $1) }
            .withLatestFrom(RxKeyboard.instance.duration.asDriver(onErrorJustReturn: nil)) { ($0, $1) }
            .drive(
                onNext: { [weak self] args in
                    let (firstPack, duration) = args
                    let (keyboardVisibleHeight, curve) = firstPack
                    
                    self?.mainContainerBottomConstraint.constant = keyboardVisibleHeight == 0 ?
                        0 :
                        keyboardVisibleHeight
                    
                    UIView.beginAnimations(nil, context: nil)
                    UIView.setAnimationCurve(curve ?? .linear)
                    UIView.setAnimationDuration(duration ?? 0.25)
                    self?.view.layoutIfNeeded()
                    UIView.commitAnimations()
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func bind() {
        let input = UserNameViewModel.Input(
            name: nameTextField.rx.text.asDriver(),
            middleName: middleNameTextField.rx.text.asDriver(),
            isNameValid: nameTextField.rx.controlEvent(.editingChanged)
                .map { [weak self] in self?.nameTextField.isValid ?? false }
                .startWith(nameTextField.isValid)
                .asDriver(onErrorJustReturn: false),
            isMiddleNameValid: middleNameTextField.rx.controlEvent(.editingChanged)
                .map { [weak self] in self?.middleNameTextField.isValid ?? false }
                .startWith(middleNameTextField.isValid)
                .asDriver(onErrorJustReturn: false),
            isAgreementAccepted: agreementAcceptedRelay.asDriver(),
            legalDocumentTrigger: legalDocumentTrigger.asDriverOnErrorJustComplete(),
            continueTrigger: continueButton.rx.tap.asDriver()
        )
        
        let output = viewModel.transform(input: input)
        
        output.isLoading
            .debounce(.milliseconds(25))
            .drive(
                onNext: { [weak self] isLoading in
                    if isLoading {
                        self?.view.endEditing(true)
                    }
                    
                    self?.updateLoader(isEnabled: isLoading, detailText: nil)
                }
            )
            .disposed(by: disposeBag)
        
        output.prepareTransitionTrigger
            .drive(
                onNext: { [weak self] in
                    self?.view.endEditing(true)
                    self?.view.isUserInteractionEnabled = false
                }
            )
            .disposed(by: disposeBag)

        output.isContinueEnabled
            .drive(continueButton.rx.isEnabled)
            .disposed(by: disposeBag)
    }

    private func configureAgreementView() {
        guard let links = makeAgreementLinks() else {
            setAgreementLayoutVisible(false)
            isAgreementAccepted = true
            return
        }

        setAgreementLayoutVisible(true)
        agreementTextView.backgroundColor = .clear
        agreementTextView.delegate = self
        agreementTextView.isEditable = false
        agreementTextView.isScrollEnabled = false
        agreementTextView.setContentHuggingPriority(.required, for: .vertical)
        agreementTextView.setContentCompressionResistancePriority(.required, for: .vertical)
        agreementTextView.tintColor = agreementLinkColor
        agreementTextView.textContainerInset = .zero
        agreementTextView.textContainer.lineFragmentPadding = 0
        agreementTextView.attributedText = makeAgreementText(links: links)
        agreementTextView.linkTextAttributes = [
            .foregroundColor: agreementLinkColor,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .underlineColor: agreementLinkColor
        ]

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleAgreement))
        agreementCheckBoxView.addGestureRecognizer(tapGesture)
        agreementCheckBoxView.isAccessibilityElement = true
        agreementCheckBoxView.accessibilityLabel = NSLocalizedString(
            "auth.userName.agreement.accessibilityLabel",
            comment: ""
        )

        updateAgreementCheckBoxAppearance()
    }

    private func setAgreementLayoutVisible(_ isVisible: Bool) {
        agreementContainerView.isHidden = !isVisible
        continueButtonAgreementTopConstraint.isActive = isVisible
        continueButtonCompactTopConstraint.isActive = !isVisible
    }

    private func makeAgreementLinks() -> [(substring: String, url: URL)]? {
        let documents: [(key: String, urlString: String?)] = [
            ("auth.userName.agreement.personalDataLinkText", Constants.personalDataProcessingAgreementURL),
            ("auth.userName.agreement.privacyPolicyLinkText", Constants.privacyPolicyURL),
            ("auth.userName.agreement.userAgreementLinkText", Constants.userAgreementURL)
        ]
        let links = documents.compactMap { document -> (substring: String, url: URL)? in
            guard
                let urlString = document.urlString?.trimmed,
                !urlString.isEmpty,
                let url = URL(string: urlString)
            else {
                return nil
            }

            return (NSLocalizedString(document.key, comment: ""), url)
        }

        return links.isEmpty ? nil : links
    }

    private func makeAgreementText(links: [(substring: String, url: URL)]) -> NSAttributedString {
        let listFormatter = ListFormatter()
        listFormatter.locale = Locale(identifier: Bundle.main.preferredLocalizations.first ?? "ru")
        let linkTexts = links.map(\.substring)
        let text = String(
            format: NSLocalizedString("auth.userName.agreement.text", comment: ""),
            listFormatter.string(from: linkTexts) ?? linkTexts.joined(separator: ", ")
        )
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .natural
        paragraphStyle.lineSpacing = 2
        let attributedString = NSMutableAttributedString(
            string: text,
            attributes: [
                .font: UIFont.SourceSansPro.regular(size: 14),
                .foregroundColor: UIColor.SmartYard.semiBlack,
                .paragraphStyle: paragraphStyle
            ]
        )

        links.forEach { substring, url in
            guard let range = text.range(of: substring) else {
                return
            }

            attributedString.addAttributes(
                [
                    .link: url,
                    .foregroundColor: agreementLinkColor,
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                    .underlineColor: agreementLinkColor
                ],
                range: NSRange(range, in: text)
            )
        }

        return attributedString
    }

    private func updateAgreementCheckBoxAppearance() {
        agreementCheckBoxView.setState(state: isAgreementAccepted ? .checkedActive : .uncheckedActive)
        agreementCheckBoxView.accessibilityTraits = isAgreementAccepted ? [.button, .selected] : .button
    }

    @objc private func toggleAgreement() {
        isAgreementAccepted.toggle()
    }

}

extension UserNameViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case nameTextField: middleNameTextField.becomeFirstResponder()
        case middleNameTextField: middleNameTextField.resignFirstResponder()
        default: break
        }
        
        return true
    }
    
}

extension UserNameViewController: UITextViewDelegate {

    func textView(
        _ textView: UITextView,
        shouldInteractWith URL: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction
    ) -> Bool {
        legalDocumentTrigger.onNext(URL)
        return false
    }

}
