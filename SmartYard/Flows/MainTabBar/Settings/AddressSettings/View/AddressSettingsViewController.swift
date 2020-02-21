//
//  AddressSettingsViewController.swift
//  SmartYard
//
//  Created by admin on 11/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import TouchAreaInsets

class AddressSettingsViewController: BaseViewController {
    
    @IBOutlet private weak var fakeNavBar: FakeNavBar!
    
    @IBOutlet private weak var addressContainerView: UIView!
    @IBOutlet private weak var addressTextField: UITextField!
    @IBOutlet private weak var editAddressButton: UIButton!
    
    @IBOutlet private weak var notificationsContainerView: UIView!
    @IBOutlet private weak var notificationsHeader: UIView!
    @IBOutlet private weak var headerArrowImageView: UIImageView!
    @IBOutlet private weak var expandedContainer: UIView!
    
    @IBOutlet private var collapsedBottomConstraint: NSLayoutConstraint!
    @IBOutlet private var expandedBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var deleteAddressButton: UIButton!
    
    private let viewModel: AddressSettingsViewModel
    
    init(viewModel: AddressSettingsViewModel) {
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
        addressContainerView.borderWidth = 1
        addressContainerView.borderColor = UIColor.SmartYard.grayBorder
        
        editAddressButton.setImage(UIImage(named: "EditIcon"), for: .normal)
        editAddressButton.setImage(UIImage(named: "EditIcon")?.darkened(), for: .highlighted)
        editAddressButton.touchAreaInsets = UIEdgeInsets(inset: 24)
        
        notificationsContainerView.borderWidth = 1
        notificationsContainerView.borderColor = UIColor.SmartYard.grayBorder
        
        deleteAddressButton.borderWidth = 1
        deleteAddressButton.borderColor = UIColor.SmartYard.grayBorder
        
        let tapGesture = UITapGestureRecognizer()
        notificationsHeader.addGestureRecognizer(tapGesture)
        
        tapGesture.rx.event
            .subscribe(
                onNext: { [weak self] _ in
                    self?.toggleNotificationsSection()
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func toggleNotificationsSection() {
        let isCollapsed = collapsedBottomConstraint.isActive
        
        if isCollapsed {
            collapsedBottomConstraint.isActive = false
            expandedBottomConstraint.isActive = true
            headerArrowImageView.image = UIImage(named: "UpArrowIcon")
        } else {
            expandedBottomConstraint.isActive = false
            collapsedBottomConstraint.isActive = true
            headerArrowImageView.image = UIImage(named: "DownArrowIcon")
        }
        
        UIView.animate(withDuration: 0.35) { [weak self] in
            self?.view.setNeedsLayout()
            self?.view.layoutIfNeeded()
        }
    }
    
    private func bind() {
        let input = AddressSettingsViewModel.Input(
            backTrigger: fakeNavBar.rx.backButtonTap.asDriver(),
            deleteTrigger: deleteAddressButton.rx.tap.asDriver()
        )
        
        let output = viewModel.transform(input)
        
        output.address
            .drive(
                onNext: { [weak self] address in
                    self?.view.endEditing(true)
                    self?.addressTextField.text = address
                    self?.addressTextField.isEnabled = false
                }
            )
            .disposed(by: disposeBag)
    }
    
}
