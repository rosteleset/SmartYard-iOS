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
    
    @IBOutlet private weak var callkitContainerView: UIView!
    @IBOutlet private weak var callkitSwitch: UISwitch!
    
    @IBOutlet private var collapsedNotificationsBottomConstraint: NSLayoutConstraint!
    @IBOutlet private var expandedNotificationsBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var logoutButton: UIButton!
    
    private let viewModel: CommonSettingsViewModel
    
    private let viewToScrollTo = BehaviorSubject<UIView?>(value: nil)
    
    private let textNotificationsTapGesture = UITapGestureRecognizer()
    private let callkitTapGesture = UITapGestureRecognizer()
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
            textNotificationsSkeleton.showSkeletonAsynchronously()
        }
        
        if balanceWarningSkeleton.sk.isSkeletonActive {
            balanceWarningSkeleton.showSkeletonAsynchronously()
        }
    }
    
    private func configureView() {
        mainContainerView.cornerRadius = 24
        mainContainerView.layer.maskedCorners = .topCorners
        
        editNameButton.setImage(UIImage(named: "pencil"), for: .normal)
        editNameButton.setImage(UIImage(named: "pencil")?.darkened(), for: .highlighted)
        editNameButton.touchAreaInsets = UIEdgeInsets(inset: 24)
        
        notificationsContainerView.borderWidth = 1
        notificationsContainerView.borderColor = UIColor.SmartYard.grayBorder
        
        logoutButton.borderWidth = 1
        logoutButton.borderColor = UIColor.SmartYard.grayBorder
        
        let notificationsTapGesture = UITapGestureRecognizer()
        notificationsHeader.addGestureRecognizer(notificationsTapGesture)
        
        notificationsTapGesture.rx.event
            .subscribe(
                onNext: { [weak self] _ in
                    self?.toggleNotificationsSection()
                }
            )
            .disposed(by: disposeBag)
        
        textNotificationsContainerView.addGestureRecognizer(textNotificationsTapGesture)
        textNotificationsSwitch.isUserInteractionEnabled = false
        
        callkitContainerView.addGestureRecognizer(callkitTapGesture)
        callkitSwitch.isUserInteractionEnabled = false
        
        balanceWarningContainerView.addGestureRecognizer(balanceWarningTapGesture)
        balanceWarningSwitch.isUserInteractionEnabled = false
    }
    
    private func toggleNotificationsSection() {
        let isCollapsed = collapsedNotificationsBottomConstraint.isActive
        
        if isCollapsed {
            collapsedNotificationsBottomConstraint.isActive = false
            expandedNotificationsBottomConstraint.isActive = true
            notificationsHeaderArrowImageView.image = UIImage(named: "UpArrowIcon")
            viewToScrollTo.onNext(notificationsContainerView)
        } else {
            expandedNotificationsBottomConstraint.isActive = false
            collapsedNotificationsBottomConstraint.isActive = true
            notificationsHeaderArrowImageView.image = UIImage(named: "DownArrowIcon")
            viewToScrollTo.onNext(nil)
        }
        
        UIView.animate(withDuration: 0.35) { [weak self] in
            self?.view.setNeedsLayout()
            self?.view.layoutIfNeeded()
        }
    }
    
    // swiftlint:disable:next function_body_length
    private func bind() {
        let input = CommonSettingsViewModel.Input(
            backTrigger: fakeNavBar.rx.backButtonTap.asDriver(),
            editNameTrigger: editNameButton.rx.tap.asDriver(),
            enableTrigger: textNotificationsTapGesture.rx.event.asDriver().mapToVoid(),
            moneyTrigger: balanceWarningTapGesture.rx.event.asDriver().mapToVoid(),
            callkitTrigger: callkitTapGesture.rx.event.asDriver().mapToVoid(),
            logoutTrigger: logoutButton.rx.tap.asDriver()
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
