//
//  AdvancedSettingsViewController.swift
//  SmartYard
//
//  Created by admin on 14/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//
// swiftlint:disable function_body_length

import UIKit
import TouchAreaInsets
import RxSwift
import RxCocoa
import JGProgressHUD

class CommonSettingsViewController: BaseViewController, LoaderPresentable {
    
    @IBOutlet private weak var fakeNavBar: FakeNavBar!
    @IBOutlet private weak var mainContainerView: UIView!
    
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
    
    @IBOutlet private var collapsedCallsBottomConstraint: NSLayoutConstraint!
    @IBOutlet private var expandedCallsBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var cacheContainerView: UIView!
    @IBOutlet private weak var cacheHeader: UIView!
    @IBOutlet private weak var cacheHeaderArrowImageView: UIImageView!
    @IBOutlet private weak var cacheSizeLabel: UILabel!
    
    @IBOutlet private weak var cacheClearButton: UIButton!
    
    @IBOutlet private var collapsedCacheBottomConstraint: NSLayoutConstraint!
    @IBOutlet private var expandedCacheBottomConstraint: NSLayoutConstraint!

    @IBOutlet private weak var logoutButton: UIButton!
    
    private let viewModel: CommonSettingsViewModel
    
    private let viewToScrollTo = BehaviorSubject<UIView?>(value: nil)
    
    private let textNotificationsTapGesture = UITapGestureRecognizer()
    private let callkitTapGesture = UITapGestureRecognizer()
    private let speakerTapGesture = UITapGestureRecognizer()
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
        
        fakeNavBar.configureBlueNavBar()
        configureView()
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if textNotificationsSkeleton.sk.isSkeletonActive {
            textNotificationsSkeleton.showSkeletonAsynchronously()
        }
        
        if balanceWarningSkeleton.sk.isSkeletonActive {
            balanceWarningSkeleton.showSkeletonAsynchronously()
        }
    }
    
    private func configureView() {
//        mainContainerView.layerCornerRadius = 24
//        mainContainerView.layer.maskedCorners = .topCorners
        
        editNameButton.setImage(UIImage(named: "pencil"), for: .normal)
        editNameButton.setImage(UIImage(named: "pencil")?.darkened(), for: .highlighted)
        editNameButton.touchAreaInsets = UIEdgeInsets(inset: 24)
        
        notificationsContainerView.layerBorderWidth = 1
        notificationsContainerView.layerBorderColor = UIColor.SmartYard.grayBorder
        notificationsContainerView.frame.size = CGSize(width: 0, height: 0)
        notificationsContainerView.isHidden = true
        
//        cacheContainerView.layerBorderWidth = 1
//        cacheContainerView.layerBorderColor = UIColor.SmartYard.grayBorder
//        cacheContainerView.frame.size = CGSize(width: 0, height: 0)
//        cacheContainerView.isHidden = false
        
        logoutButton.layerBorderWidth = 1
        logoutButton.layerBorderColor = UIColor.SmartYard.grayBorder
        
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
        
        let cacheTapGesture = UITapGestureRecognizer()
        cacheHeader.addGestureRecognizer(cacheTapGesture)
        
        cacheTapGesture.rx.event
            .subscribe(
                onNext: { [weak self] _ in
                    self?.toggleCacheSection()
                }
            )
        
        textNotificationsContainerView.addGestureRecognizer(textNotificationsTapGesture)
        textNotificationsSwitch.isUserInteractionEnabled = false
        
        balanceWarningContainerView.addGestureRecognizer(balanceWarningTapGesture)
        balanceWarningSwitch.isUserInteractionEnabled = false
        
        callkitContainerView.addGestureRecognizer(callkitTapGesture)
        callkitSwitch.isUserInteractionEnabled = false
        
        speakerContainerView.addGestureRecognizer(speakerTapGesture)
        speakerSwitch.isUserInteractionEnabled = false
        
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
    
    private func toggleCacheSection() {
        toggleSection(
            collapsedBottomConstraint: collapsedCacheBottomConstraint,
            expandedBottomConstraint: expandedCacheBottomConstraint,
            headerArrowImageView: cacheHeaderArrowImageView,
            containerView: cacheContainerView
        )
    }
    
    private func bind() {
        let input = CommonSettingsViewModel.Input(
            backTrigger: fakeNavBar.rx.backButtonTap.asDriver(),
            editNameTrigger: editNameButton.rx.tap.asDriver(),
            enableTrigger: textNotificationsTapGesture.rx.event.asDriver().mapToVoid(),
            moneyTrigger: balanceWarningTapGesture.rx.event.asDriver().mapToVoid(),
            callkitTrigger: callkitTapGesture.rx.event.asDriver().mapToVoid(),
            speakerTrigger: speakerTapGesture.rx.event.asDriver().mapToVoid(),
            logoutTrigger: logoutButton.rx.tap.asDriver(),
            clearCacheTrigger: cacheClearButton.rx.tap.asDriver()
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
            .drive(
                onNext: { [weak self] state in
                    self?.textNotificationsSwitch.setOn(state, animated: true)
                }
            )
            .disposed(by: disposeBag)
        
        output.enableAccountBalanceWarning
            .drive(
                onNext: { [weak self] state in
                    self?.balanceWarningSwitch.setOn(state, animated: true)
                }
            )
            .disposed(by: disposeBag)
        
        output.enableCallkit
            .drive(
                onNext: { [weak self] state in
                    self?.callkitSwitch.setOn(state, animated: true)
                }
            )
            .disposed(by: disposeBag)
        
        output.enableSpeakerByDefault
            .drive(
                onNext: { [weak self] state in
                    self?.speakerSwitch.setOn(state, animated: true)
                }
            )
            .disposed(by: disposeBag)
        
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
        
        output.shouldShowInitialLoading
            .drive(
                onNext: { [weak self] shouldShowInitialLoading in
                    shouldShowInitialLoading ? self?.showInitialLoading() : self?.finishInitialLoading()
                }
            )
            .disposed(by: disposeBag)
        
        output.cacheSize
            .drive(
                onNext: { [weak self] size in
                    self?.cacheSizeLabel.text = size
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func showInitialLoading() {
        textNotificationsSwitch.isHidden = true
        textNotificationsTapGesture.isEnabled = false
        textNotificationsSkeleton.isHidden = false
        textNotificationsSkeleton.showSkeletonAsynchronously()
        
        balanceWarningSwitch.isHidden = true
        balanceWarningTapGesture.isEnabled = false
        balanceWarningSkeleton.isHidden = false
        balanceWarningSkeleton.showSkeletonAsynchronously()
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
    
}
// swiftlint:enable function_body_length
