//
//  AddressSettingsViewController.swift
//  SmartYard
//
//  Created by admin on 11/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import TouchAreaInsets
import JGProgressHUD

class AddressSettingsViewController: BaseViewController, LoaderPresentable {
    
    @IBOutlet private weak var fakeNavBar: FakeNavBar!
    
    @IBOutlet private weak var addressContainerView: UIView!
    @IBOutlet private weak var addressTextField: UITextField!
    @IBOutlet private weak var editAddressButton: UIButton!
    
    @IBOutlet private weak var notificationsContainerView: UIView!
    @IBOutlet private weak var notificationsHeader: UIView!
    @IBOutlet private weak var headerArrowImageView: UIImageView!
    @IBOutlet private weak var expandedContainer: UIView!
    
    @IBOutlet private weak var mainContainerView: UIView!
    @IBOutlet private weak var skeletonView: AddressSettingsSkeletonView!
    
    @IBOutlet private weak var cmsContainerView: UIView!
    @IBOutlet private weak var cmsSwitch: UISwitch!
    
    @IBOutlet private weak var voipContainerView: UIView!
    @IBOutlet private weak var voipSwitch: UISwitch!
    
    @IBOutlet private var collapsedBottomConstraint: NSLayoutConstraint!
    @IBOutlet private var expandedBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var deleteAddressButton: UIButton!
    
    private let viewModel: AddressSettingsViewModel
    
    private let cmsTapGesture = UITapGestureRecognizer()
    private let voipTapGesture = UITapGestureRecognizer()
    
    var loader: JGProgressHUD?
    
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if skeletonView.isSkeletonActive {
            skeletonView.showSkeletonAsynchronously()
        }
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
        
        let expansionTapGesture = UITapGestureRecognizer()
        notificationsHeader.addGestureRecognizer(expansionTapGesture)
        
        expansionTapGesture.rx.event
            .subscribe(
                onNext: { [weak self] _ in
                    self?.toggleNotificationsSection()
                }
            )
            .disposed(by: disposeBag)
        
        cmsContainerView.addGestureRecognizer(cmsTapGesture)
        cmsSwitch.isUserInteractionEnabled = false
        
        voipContainerView.addGestureRecognizer(voipTapGesture)
        voipSwitch.isUserInteractionEnabled = false
        
        mainContainerView.isHidden = true
        skeletonView.isHidden = false
        skeletonView.showSkeletonAsynchronously()
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
            deleteTrigger: deleteAddressButton.rx.tap.asDriver(),
            cmsTrigger: cmsTapGesture.rx.event.asDriver().mapToVoid(),
            voipTrigger: voipTapGesture.rx.event.asDriver().mapToVoid()
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
        
        output.isCmsEnabled
            .drive(
                onNext: { [weak self] state in
                    self?.cmsSwitch.setOn(!state, animated: true)
                }
            )
            .disposed(by: disposeBag)
        
        output.areCallsEnabled
            .drive(
                onNext: { [weak self] state in
                    self?.voipSwitch.setOn(state, animated: true)
                }
            )
            .disposed(by: disposeBag)
        
        output.isLoading
            .debounce(.milliseconds(25))
            .drive(
                onNext: { [weak self] isLoading in
                    self?.updateLoader(isEnabled: isLoading, detailText: nil)
                }
            )
            .disposed(by: disposeBag)
        
        output.isInitialLoadingFinished
            .distinctUntilChanged()
            .isTrue()
            .delay(.milliseconds(500))
            .drive(
                onNext: { [weak self] _ in
                    self?.mainContainerView.isHidden = false
                    self?.skeletonView.hideSkeleton()
                    self?.skeletonView.isHidden = true
                }
            )
            .disposed(by: disposeBag)
    }
    
}
