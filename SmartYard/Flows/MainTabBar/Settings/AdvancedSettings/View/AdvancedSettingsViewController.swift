//
//  AdvancedSettingsViewController.swift
//  SmartYard
//
//  Created by admin on 14/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import TouchAreaInsets

class AdvancedSettingsViewController: BaseViewController {
    
    @IBOutlet private weak var fakeNavBar: FakeNavBar!
    
    @IBOutlet private weak var nameContainerView: UIView!
    @IBOutlet private weak var nameTextField: UITextField!
    @IBOutlet private weak var editNameButton: UIButton!
    
    @IBOutlet private weak var notificationsContainerView: UIView!
    @IBOutlet private weak var notificationsHeader: UIView!
    @IBOutlet private weak var notificationsHeaderArrowImageView: UIImageView!
    
    @IBOutlet private var collapsedNotificationsBottomConstraint: NSLayoutConstraint!
    @IBOutlet private var expandedNotificationsBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var securityContainerView: UIView!
    @IBOutlet private weak var securityHeader: UIView!
    @IBOutlet private weak var securityHeaderArrowImageView: UIImageView!
    
    @IBOutlet private var collapsedSecurityBottomConstraint: NSLayoutConstraint!
    @IBOutlet private var expandedSecurityBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var logoutButton: UIButton!
    
    private let viewModel: AdvancedSettingsViewModel
    
    init(viewModel: AdvancedSettingsViewModel) {
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
    
    private func configureView() {
        nameContainerView.borderWidth = 1
        nameContainerView.borderColor = UIColor.SmartYard.grayBorder
        
        editNameButton.setImage(UIImage(named: "EditIcon"), for: .normal)
        editNameButton.setImage(UIImage(named: "EditIcon")?.darkened(), for: .highlighted)
        editNameButton.touchAreaInsets = UIEdgeInsets(inset: 24)
        
        notificationsContainerView.borderWidth = 1
        notificationsContainerView.borderColor = UIColor.SmartYard.grayBorder
        
        securityContainerView.borderWidth = 1
        securityContainerView.borderColor = UIColor.SmartYard.grayBorder
        
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
        
        let securityTapGesture = UITapGestureRecognizer()
        securityHeader.addGestureRecognizer(securityTapGesture)
        
        securityTapGesture.rx.event
            .subscribe(
                onNext: { [weak self] _ in
                    self?.toggleSecuritySection()
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func toggleNotificationsSection() {
        let isCollapsed = collapsedNotificationsBottomConstraint.isActive
        
        if isCollapsed {
            collapsedNotificationsBottomConstraint.isActive = false
            expandedNotificationsBottomConstraint.isActive = true
            notificationsHeaderArrowImageView.image = UIImage(named: "UpArrowIcon")
        } else {
            expandedNotificationsBottomConstraint.isActive = false
            collapsedNotificationsBottomConstraint.isActive = true
            notificationsHeaderArrowImageView.image = UIImage(named: "DownArrowIcon")
        }
        
        UIView.animate(withDuration: 0.35) { [weak self] in
            self?.view.setNeedsLayout()
            self?.view.layoutIfNeeded()
        }
    }
    
    private func toggleSecuritySection() {
        let isCollapsed = collapsedSecurityBottomConstraint.isActive
        
        if isCollapsed {
            collapsedSecurityBottomConstraint.isActive = false
            expandedSecurityBottomConstraint.isActive = true
            securityHeaderArrowImageView.image = UIImage(named: "UpArrowIcon")
        } else {
            expandedSecurityBottomConstraint.isActive = false
            collapsedSecurityBottomConstraint.isActive = true
            securityHeaderArrowImageView.image = UIImage(named: "DownArrowIcon")
        }
        
        UIView.animate(withDuration: 0.35) { [weak self] in
            self?.view.setNeedsLayout()
            self?.view.layoutIfNeeded()
        }
    }
    
    private func bind() {
        let input = AdvancedSettingsViewModel.Input(backTrigger: fakeNavBar.rx.backButtonTap.asDriver())
        
        let output = viewModel.transform(input)
        
        output.name
            .drive(
                onNext: { [weak self] name in
                    self?.view.endEditing(true)
                    self?.nameTextField.text = name
                    self?.nameTextField.isEnabled = false
                }
            )
            .disposed(by: disposeBag)
    }
    
}
