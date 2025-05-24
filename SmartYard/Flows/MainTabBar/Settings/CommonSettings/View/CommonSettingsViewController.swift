//
//  AdvancedSettingsViewController.swift
//  SmartYard
//
//  Created by admin on 14/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import TouchAreaInsets
import RxSwift
import RxCocoa
import JGProgressHUD

final class CommonSettingsViewController: BaseViewController, LoaderPresentable {
    
    @IBOutlet private weak var fakeNavBar: FakeNavBar!
    @IBOutlet private weak var mainContainerView: UIView!
    
    @IBOutlet private weak var nameContainerView: UIView!
    @IBOutlet private weak var nameTextLabel: UILabel!
    @IBOutlet private weak var phoneTextLabel: UILabel!
    
    @IBOutlet private weak var editNameButton: UIButton!
    
    @IBOutlet private weak var notificationsContainerView: UIView!
    @IBOutlet private weak var notificationsHeader: UIView!
    @IBOutlet private weak var notificationsHeaderArrowImageView: UIImageView!
    
    @IBOutlet private weak var textNotificationsContainerView: UIView!
    @IBOutlet private weak var textNotificationsSwitch: UISwitch!
    @IBOutlet private weak var textNotificationsSkeleton: UIView!
    
    @IBOutlet private weak var balanceWarningContainerView: UIView!
    @IBOutlet private weak var balanceWarningSwitch: UISwitch!
    @IBOutlet private weak var balanceWarningSkeleton: UIView!
    
    @IBOutlet private var collapsedNotificationsBottomConstraint: NSLayoutConstraint!
    @IBOutlet private var expandedNotificationsBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var callsContainerView: UIView!
    @IBOutlet private weak var callsHeader: UIView!
    @IBOutlet private weak var callsHeaderArrowImageView: UIImageView!
    
    @IBOutlet private weak var speakerContainerView: UIView!
    @IBOutlet private weak var speakerSwitch: UISwitch!
    
    @IBOutlet private weak var callkitContainerView: UIView!
    @IBOutlet private weak var callkitSwitch: UISwitch!
    @IBOutlet private weak var callkitQuestionMark: UIButton!
    
    @IBOutlet private var collapsedCallsBottomConstraint: NSLayoutConstraint!
    @IBOutlet private var expandedCallsBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var displayContainerView: UIView!
    @IBOutlet private weak var displayHeader: UIView!
    @IBOutlet private weak var displayHeaderArrowImageView: UIImageView!
    
    @IBOutlet private weak var addressOrderResetButton: SmartYardActionModeButton!
    @IBOutlet private weak var addressOrderQuestionMark: UIButton!
    
    @IBOutlet private weak var showCamerasOnMapContainerView: UIView!
    @IBOutlet private weak var showCamerasOnMapSwitch: UISwitch!
    
    @IBOutlet private weak var appearanceContainerView: UIView!
    @IBOutlet private weak var appearanceHighSeparator: UIView!
    @IBOutlet private weak var changeAppereanceButton: UIButton!
    
    @IBOutlet private var сollapsedDisplayBottomConstraint: NSLayoutConstraint!
    @IBOutlet private var expandedDisplayBottomConstaint: NSLayoutConstraint!
    
    @IBOutlet private weak var logoutButton: UIButton!
    @IBOutlet private weak var deleteAccountButton: UIButton!
    
    @IBOutlet private weak var deleteAccountBottomConstraint: NSLayoutConstraint!
    
    private let viewModel: CommonSettingsViewModel
    
    private let viewToScrollTo = BehaviorSubject<UIView?>(value: nil)
    
    private let textNotificationsTapGesture = UITapGestureRecognizer()
    private let callkitTapGesture = UITapGestureRecognizer()
    private let speakerTapGesture = UITapGestureRecognizer()
    private let enableListTapGesture = UITapGestureRecognizer()
    private let balanceWarningTapGesture = UITapGestureRecognizer()
    
    var loader: JGProgressHUD?
    
    init(viewModel: CommonSettingsViewModel) {
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if textNotificationsSkeleton.sk.isSkeletonActive {
            textNotificationsSkeleton.showSkeletonAsynchronously(with: UIColor.SmartYard.backgroundColor)
        }
        
        if balanceWarningSkeleton.sk.isSkeletonActive {
            balanceWarningSkeleton.showSkeletonAsynchronously(with: UIColor.SmartYard.backgroundColor)
        }
    }
    
    private func configureView() {
        mainContainerView.layerCornerRadius = 24
        mainContainerView.layer.maskedCorners = .topCorners
        
        editNameButton.setImage(UIImage(named: "pencil"), for: .normal)
        editNameButton.setImage(UIImage(named: "pencil")?.darkened(), for: .highlighted)
        editNameButton.touchAreaInsets = UIEdgeInsets(inset: 24)
        
        addressOrderResetButton.mode = .reset
        changeAppereanceButton.setTitle("Как в системе", for: .normal)

        [
            nameContainerView,
            notificationsContainerView,
            callsContainerView,
            speakerContainerView,
            displayContainerView,
            logoutButton,
            deleteAccountButton
        ].forEach { $0.addBorder(dynamicColor: UIColor.SmartYard.grayBorder) }
        
        let notificationsTapGesture = UITapGestureRecognizer()
        notificationsHeader.addGestureRecognizer(notificationsTapGesture)
        
        notificationsTapGesture.rx.event
            .subscribe(
                onNext: { [weak self] _ in
                    self?.toggleNotificationsSection()
                }
            )
            .disposed(by: disposeBag)
        
        let callsTapGesture = UITapGestureRecognizer()
        callsHeader.addGestureRecognizer(callsTapGesture)
        
        callsTapGesture.rx.event
            .subscribe(
                onNext: { [weak self] _ in
                    self?.toggleCallsSection()
                }
            )
            .disposed(by: disposeBag)
        
        let displayHeaderTapGesture = UITapGestureRecognizer()
        displayHeader.addGestureRecognizer(displayHeaderTapGesture)
        
        displayHeaderTapGesture.rx.event
            .subscribe(
                onNext: { [weak self] _ in
                    self?.toggleDisplaySection()
                }
            )
            .disposed(by: disposeBag)
                
        if !Constants.showDeleteAccountButton {
            deleteAccountButton.removeFromSuperview()
            deleteAccountBottomConstraint.isActive = false
        }
    }
    
    private func toggleSection(
        collapsedBottomConstraint: NSLayoutConstraint,
        expandedBottomConstraint: NSLayoutConstraint,
        headerArrowImageView: UIImageView,
        containerView: UIView
    ) {
        let isCollapsed = collapsedBottomConstraint.isActive
        
        if isCollapsed {
            collapsedBottomConstraint.isActive = false
            expandedBottomConstraint.isActive = true
            headerArrowImageView.image = UIImage(named: "UpArrowIcon")
            viewToScrollTo.onNext(containerView)
        } else {
            expandedBottomConstraint.isActive = false
            collapsedBottomConstraint.isActive = true
            headerArrowImageView.image = UIImage(named: "DownArrowIcon")
            viewToScrollTo.onNext(nil)
        }
        
        UIView.animate(withDuration: 0.35) { [weak self] in
            self?.view.setNeedsLayout()
            self?.view.layoutIfNeeded()
        }
    }
    
    private func toggleNotificationsSection() {
        toggleSection(
            collapsedBottomConstraint: collapsedNotificationsBottomConstraint,
            expandedBottomConstraint: expandedNotificationsBottomConstraint,
            headerArrowImageView: notificationsHeaderArrowImageView,
            containerView: notificationsContainerView
        )
    }
    
    private func toggleCallsSection() {
        toggleSection(
            collapsedBottomConstraint: collapsedCallsBottomConstraint,
            expandedBottomConstraint: expandedCallsBottomConstraint,
            headerArrowImageView: callsHeaderArrowImageView,
            containerView: callsContainerView
        )
    }
    
    private func toggleDisplaySection() {
        toggleSection(
            collapsedBottomConstraint: сollapsedDisplayBottomConstraint,
            expandedBottomConstraint: expandedDisplayBottomConstaint,
            headerArrowImageView: displayHeaderArrowImageView,
            containerView: displayContainerView
        )
    }
    
    // swiftlint:disable:next function_body_length
    private func bind() {
        let input = CommonSettingsViewModel.Input(
            backTrigger: fakeNavBar.rx.backButtonTap.asDriver(),
            editNameTrigger: editNameButton.rx.tap.asDriver(),
            showNotificationTrigger: textNotificationsSwitch.rx.isOn.asDriver().mapToVoid(),
            moneyTrigger: balanceWarningSwitch.rx.isOn.asDriver().mapToVoid(),
            callkitTrigger: callkitSwitch.rx.isOn.asDriver().mapToVoid(),
            speakerTrigger: speakerSwitch.rx.isOn.asDriver().mapToVoid(),
            showCamerasOnMapTrigger: showCamerasOnMapSwitch.rx.isOn.asDriver().mapToVoid(),
            showApereanceApert: changeAppereanceButton.rx.tap.asDriver().mapToVoid(),
            logoutTrigger: logoutButton.rx.tap.asDriver(),
            deleteAccountTrigger: deleteAccountButton.rx.tap.asDriver(),
            callKitHintTrigger: callkitQuestionMark.rx.tap.asDriver(),
            addressOrderHintTrigger: addressOrderQuestionMark.rx.tap.asDriver(),
            addressOrderTrigger: addressOrderResetButton.rx.tap.asDriver()
        )
        
        let output = viewModel.transform(input)
        
        output.name
            .drive(
                onNext: { [weak self] name in
                    self?.nameTextLabel.text = name
                }
            )
            .disposed(by: disposeBag)
        
        output.phone
            .drive(
                onNext: { [weak self] phone in
                    self?.phoneTextLabel.text = phone
                }
            )
            .disposed(by: disposeBag)
        
        output.enableNotifications
            .drive(textNotificationsSwitch.rx.isOn)
            .disposed(by: disposeBag)
        
        output.enableAccountBalanceWarning
            .drive(balanceWarningSwitch.rx.isOn)
            .disposed(by: disposeBag)
        
        output.enableCallkit
            .drive(callkitSwitch.rx.isOn)
            .disposed(by: disposeBag)
        
        output.enableSpeakerByDefault
            .drive(speakerSwitch.rx.isOn)
            .disposed(by: disposeBag)
        
        output.showCamerasOnMap
            .drive(showCamerasOnMapSwitch.rx.isOn)
            .disposed(by: disposeBag)
        
        output.displaySettings
            .drive(
                onNext: {  [weak self] isListVisible, isAppearanceVisible in
                    guard let self = self else { return }
    
                    configureViewVisibility(
                        appearanceContainerView,
                        isVisible: isAppearanceVisible
                    )
                    configureViewVisibility(
                        showCamerasOnMapContainerView,
                        isVisible: isListVisible
                    )
                }
            )
            .disposed(by: disposeBag)
        
        output.appereanceButtonText
            .drive(
                onNext: { [weak self] text in
                    self?.changeAppereanceButton.setTitle(NSLocalizedString(text, comment: ""), for: .normal)
                }
            )
            .disposed(by: disposeBag)
        
        output.isLoading
            .debounce(RxTimeInterval.milliseconds(25))
            .drive(
                onNext: { [weak self] (isLoading: Bool) in
                    if isLoading {
                        self?.view.endEditing(true)
                    }
                    
                    self?.updateLoader(isEnabled: isLoading, detailText: nil)
                }
            )
            .disposed(by: disposeBag)
        
        output.shouldShowInitialLoading
            .drive(
                onNext: { [weak self] shouldShowInitialLoading in
                    shouldShowInitialLoading ? self?.showInitialLoading() : self?.finishInitialLoading()
                }
            )
            .disposed(by: disposeBag)
        
        output.resetDidComplete
            .drive(onNext: { [weak self] in
                guard let self = self else { return }

                UIView.transition(
                    with: self.addressOrderResetButton,
                    duration: 0.25,
                    options: [.transitionCrossDissolve]
                ) {
                    self.addressOrderResetButton.isOn = true
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    UIView.transition(
                        with: self.addressOrderResetButton,
                        duration: 0.25,
                        options: [.transitionCrossDissolve]
                    ) {
                        self.addressOrderResetButton.isOn = false
                    }
                }

            })
            .disposed(by: disposeBag)
    }
    
    private func showInitialLoading() {
        textNotificationsSwitch.isHidden = true
        textNotificationsTapGesture.isEnabled = false
        textNotificationsSkeleton.isHidden = false
        textNotificationsSkeleton.showSkeletonAsynchronously(with: UIColor.SmartYard.backgroundColor)
        
        balanceWarningSwitch.isHidden = true
        balanceWarningTapGesture.isEnabled = false
        balanceWarningSkeleton.isHidden = false
        balanceWarningSkeleton.showSkeletonAsynchronously(with: UIColor.SmartYard.backgroundColor)
    }
    
    private func finishInitialLoading() {
        // MARK: Если показать сразу, то пользователь увидит, как меняется положение тумблеров
        // Т.к. мы подгружаем стейт с сервера. Поэтому решил это закрыть за скелетоном
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.textNotificationsSwitch.isHidden = false
            self?.textNotificationsTapGesture.isEnabled = true
            self?.textNotificationsSkeleton.isHidden = true
            self?.textNotificationsSkeleton.hideSkeleton()
            
            self?.balanceWarningSwitch.isHidden = false
            self?.balanceWarningTapGesture.isEnabled = true
            self?.balanceWarningSkeleton.isHidden = true
            self?.balanceWarningSkeleton.hideSkeleton()
        }
    }
    
    private func configureViewVisibility(_ view: UIView, isVisible: Bool, height: CGFloat = 0) {
        view.isHidden = !isVisible
        view.heightAnchor.constraint(equalToConstant: isVisible ? height : 0).isActive = !isVisible
    }
    
}

extension CommonSettingsViewController {
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        [
            nameContainerView,
            notificationsContainerView,
            callsContainerView,
            speakerContainerView,
            displayContainerView,
            logoutButton,
            deleteAccountButton
        ].forEach { $0.addBorder(dynamicColor: UIColor.SmartYard.grayBorder) }
    }
    
}
