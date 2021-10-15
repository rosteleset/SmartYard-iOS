//
//  AddressSettingsViewController.swift
//  SmartYard
//
//  Created by admin on 11/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import TouchAreaInsets
import JGProgressHUD

class AddressSettingsViewController: BaseViewController, LoaderPresentable {
    
    @IBOutlet private weak var fakeNavBar: FakeNavBar!
    
    @IBOutlet private weak var addressContainerView: UIView!
    @IBOutlet private weak var addressLabel: UILabel!
    
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
    
    @IBOutlet private weak var whiteRabbitContainerView: UIView!
    @IBOutlet private weak var whiteRabbitSwitch: UISwitch!
    @IBOutlet private weak var whiteRabbitQuestionMark: UIButton!
    
    @IBOutlet private weak var paperContainerView: UIView!
    @IBOutlet private weak var paperSwitch: UISwitch!
    
    @IBOutlet private weak var logsContainerView: UIView!
    @IBOutlet private weak var logsSwitch: UISwitch!
    
    @IBOutlet private weak var hiddenContainerView: UIView!
    @IBOutlet private weak var hiddenSwitch: UISwitch!
    
    @IBOutlet private weak var frsContainerView: UIView!
    @IBOutlet private weak var frsSwitch: UISwitch!
    
    @IBOutlet private var collapsedBottomConstraint: NSLayoutConstraint!
    @IBOutlet private var expandedBottomConstraint: NSLayoutConstraint!
    @IBOutlet private var deleteButtonTopToNotificationsConstraint: NSLayoutConstraint!
    @IBOutlet private var notificationsViewTopConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var deleteAddressButton: UIButton!
    
    private let viewModel: AddressSettingsViewModel
    
    private let cmsTapGesture = UITapGestureRecognizer()
    private let voipTapGesture = UITapGestureRecognizer()
    private let whiteRabbitTapGesture = UITapGestureRecognizer()
    private let paperBillTapGesture = UITapGestureRecognizer()
    private let logsTapGesture = UITapGestureRecognizer()
    private let hiddenTapGesture = UITapGestureRecognizer()
    private let frsTapGesture = UITapGestureRecognizer()
    
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
        
        if skeletonView.sk.isSkeletonActive {
            skeletonView.showSkeletonAsynchronously()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // MARK: 24 px = это то, насколько addressContainerView выступает над scrollView
        // 8 px - это отступ между addressContainerView и следующей за ней вьюхой
        let neededInset = addressContainerView.bounds.height - 24 + 8
        
        notificationsViewTopConstraint.constant = neededInset
    }
    
    private func configureView() {
        addressContainerView.borderWidth = 1
        addressContainerView.borderColor = UIColor.SmartYard.grayBorder
        
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
        
        whiteRabbitContainerView.addGestureRecognizer(whiteRabbitTapGesture)
        whiteRabbitSwitch.isUserInteractionEnabled = false
        
        paperContainerView.addGestureRecognizer(paperBillTapGesture)
        paperSwitch.isUserInteractionEnabled = false
        
        logsContainerView.addGestureRecognizer(logsTapGesture)
        logsSwitch.isUserInteractionEnabled = false
        
        hiddenContainerView.addGestureRecognizer(hiddenTapGesture)
        hiddenSwitch.isUserInteractionEnabled = false
        
        frsContainerView.addGestureRecognizer(frsTapGesture)
        frsSwitch.isUserInteractionEnabled = false
        
        skeletonView.isHidden = true
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
    
    // swiftlint:disable:next function_body_length
    private func bind() {
        let input = AddressSettingsViewModel.Input(
            backTrigger: fakeNavBar.rx.backButtonTap.asDriver(),
            deleteTrigger: deleteAddressButton.rx.tap.asDriver(),
            cmsTrigger: cmsTapGesture.rx.event.asDriver().mapToVoid(),
            voipTrigger: voipTapGesture.rx.event.asDriver().mapToVoid(),
            whiteRabbitTrigger: whiteRabbitTapGesture.rx.event.asDriver().mapToVoid(),
            paperBillTrigger: paperBillTapGesture.rx.event.asDriver().mapToVoid(),
            logsTrigger: logsTapGesture.rx.event.asDriver().mapToVoid(),
            hiddenTrigger: hiddenTapGesture.rx.event.asDriver().mapToVoid(),
            frsTrigger: frsTapGesture.rx.event.asDriver().mapToVoid(),
            whiteRabbitHintTrigger: whiteRabbitQuestionMark.rx.tap.asDriver()
        )
        
        let output = viewModel.transform(input)
        
        output.address
            .drive(
                onNext: { [weak self] address in
                    self?.addressLabel.text = address
                }
            )
            .disposed(by: disposeBag)
        
        output.isCmsEnabled
            .drive(
                onNext: { [weak self] state in
                    self?.cmsSwitch.setOn(state, animated: true)
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
        
        output.isWhiteRabbitEnabled
            .drive(
                onNext: { [weak self] state in
                    self?.whiteRabbitSwitch.setOn(state, animated: true)
                }
            )
            .disposed(by: disposeBag)
        
        output.arePaperBillsEnabled
            .drive(
                onNext: { [weak self] state in
                    
                    guard let state = state else {
                        self?.paperContainerView.isHidden = true
                        return
                    }
                    self?.paperContainerView.isHidden = false
                    self?.paperSwitch.setOn(state, animated: true)
                }
            )
            .disposed(by: disposeBag)
        
        output.areLogsEnabled
            .drive(
                onNext: { [weak self] state in
                    
                    guard let state = state else {
                        self?.logsContainerView.isHidden = true
                        return
                    }
                    self?.logsContainerView.isHidden = false
                    self?.logsSwitch.setOn(state, animated: true)
                }
            )
            .disposed(by: disposeBag)
        
        output.areLogsVisibleOnlyForOwner
            .drive(
                onNext: { [weak self] state in
                    
                    guard let state = state else {
                        self?.hiddenContainerView.isHidden = true
                        return
                    }
                    self?.hiddenContainerView.isHidden = false
                    self?.hiddenSwitch.setOn(state, animated: true)
                }
            )
            .disposed(by: disposeBag)
        
        output.isFRSEnabled
            .drive(
                onNext: { [weak self] state in
                    
                    guard let state = state else {
                        self?.frsContainerView.isHidden = true
                        return
                    }
                    self?.frsContainerView.isHidden = false
                    self?.frsSwitch.setOn(state, animated: true)
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
        
        output.shouldBlockInteraction
            .withLatestFrom(output.hasDomophone) { ($0, $1) }
            .drive(
                onNext: { [weak self] args in
                    let (shouldBlockInteraction, hasDomophone) = args
                    
                    let showSkeleton = {
                        self?.mainContainerView.isHidden = true
                        self?.skeletonView.isHidden = false
                        self?.skeletonView.showSkeletonAsynchronously()
                    }
                    
                    let hideSkeleton = {
                        self?.mainContainerView.isHidden = false
                        self?.skeletonView.isHidden = true
                        self?.skeletonView.hideSkeleton()
                    }
                    
                    // MARK: Если есть домофон, то лучше задержать скелетон на некоторое время
                    // Иначе юзер может увидеть, как тумблеры меняют свое значение согласно загруженному стейту
                    
                    switch (shouldBlockInteraction, hasDomophone) {
                    case (true, _):
                        showSkeleton()
                        
                    case (false, false):
                        hideSkeleton()
                        
                    case (false, true):
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            hideSkeleton()
                        }
                    }
                }
            )
            .disposed(by: disposeBag)
        
        output.hasDomophone
            .drive(
                onNext: { [weak self] hasDomophone in
                    self?.deleteButtonTopToNotificationsConstraint.isActive = hasDomophone
                    self?.notificationsContainerView.isHidden = !hasDomophone
                }
            )
            .disposed(by: disposeBag)
    }
    
}
