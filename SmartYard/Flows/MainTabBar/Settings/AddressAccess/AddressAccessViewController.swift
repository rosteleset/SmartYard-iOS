//
//  AddressAccessViewController.swift
//  SmartYard
//
//  Created by Mad Brains on 14.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//
// swiftlint:disable function_body_length line_length

import UIKit
import RxCocoa
import RxSwift
import JGProgressHUD

class AddressAccessViewController: BaseViewController, LoaderPresentable {

    @IBOutlet private weak var fakeNavBar: FakeNavBar!
    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var addressView: FullRoundedView!
    @IBOutlet private weak var intercomAccessView: IntercomTemporaryAccessView!
    @IBOutlet private weak var faceIdAccessView: FaceIdAccessView!
    
    @IBOutlet private weak var temporaryAccessContainer: UIView!
    @IBOutlet private weak var temporaryAccessView: AccessView!
    
    @IBOutlet private weak var permanentAccessContainer: UIView!
    @IBOutlet private weak var permanentAccessView: AccessView!
    
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var skeletonView: AddressAccessSkeletonView!
    
    var loader: JGProgressHUD?
    
    private let viewModel: AddressAccessViewModel
    
    private var tempAccessViewHeightConstraint: NSLayoutConstraint!
    private var permanentAccessViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet private var stackViewTopConstraint: NSLayoutConstraint!
    
    init(viewModel: AddressAccessViewModel) {
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
        
        // MARK: 24 px = это то, насколько addressView выступает над scrollView
        // 16 px - это отступ между addressView и следующей за ней вьюхой
        let neededInset = addressView.bounds.height - 24 + 16
        
        stackViewTopConstraint.constant = neededInset
    }
    
    private func configureView() {
        let temporaryViewHeight = temporaryAccessView.heightAnchor.constraint(equalToConstant: 57)
        temporaryViewHeight.isActive = true
        tempAccessViewHeightConstraint = temporaryViewHeight
        
        let permanentViewHeight = permanentAccessView.heightAnchor.constraint(equalToConstant: 57)
        permanentViewHeight.isActive = true
        permanentAccessViewHeightConstraint = permanentViewHeight
        
        temporaryAccessView.translatesAutoresizingMaskIntoConstraints = false
        permanentAccessView.translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.isHidden = true
        skeletonView.isHidden = false
        skeletonView.showSkeletonAsynchronously()
    }
    
    private func bind() {
        let input = AddressAccessViewModel.Input(
            viewDidAppearTrigger: rx.viewWillAppear.asDriverOnErrorJustComplete(),
            refreshIntercomTempCodeTrigger: intercomAccessView.rx.refreshButtonTapped.asDriverOnErrorJustComplete(),
            openGuestAccessTrigger: intercomAccessView.rx.openButtonTapped.asDriverOnErrorJustComplete(),
            waitingGuestsHintTrigger: intercomAccessView.rx.waitingGuestsQuestionMarkTapped.asDriverOnErrorJustComplete(),
            configureFaces: faceIdAccessView.rx.configureButtonTapped.asDriverOnErrorJustComplete(),
            smsToTempContactTrigger: temporaryAccessView.sendSmsSubject.asDriverOnErrorJustComplete(),
            smsToPermanentContactTrigger: permanentAccessView.sendSmsSubject.asDriverOnErrorJustComplete(),
            deleteTempContactTrigger: temporaryAccessView.deletePressedSubject.asDriverOnErrorJustComplete(),
            deletePermanentContactTrigger: permanentAccessView.deletePressedSubject.asDriverOnErrorJustComplete(),
            addNewTempContact: temporaryAccessView.addNewPersonSubject.asDriverOnErrorJustComplete(),
            addNewPermanentContact: permanentAccessView.addNewPersonSubject.asDriverOnErrorJustComplete(),
            backTrigger: fakeNavBar.rx.backButtonTap.asDriver()
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
        
        output.objectAddress
            .drive(
                onNext: { [weak self] address in
                    self?.addressLabel.text = address
                }
            )
            .disposed(by: disposeBag)
        
        output.permanentAccessContacts
            .withLatestFrom(output.isInitialLoadingFinished) { ($0, $1) }
            .drive(
                onNext: { [weak self] args in
                    let (contacts, isInitialLoadingFinished) = args
                    
                    guard let self = self else {
                        return
                    }
                    
                    self.permanentAccessView.viewModel.updateData(data: contacts)
                    
                    let newHeight = self.calculateAccessViewHeight(countItems: contacts.count)
                    self.permanentAccessViewHeightConstraint.constant = newHeight
                    
                    UIView.animate(withDuration: isInitialLoadingFinished ? 0.25 : 0) { [weak self] in
                        self?.view.layoutIfNeeded()
                    }
                }
            )
            .disposed(by: disposeBag)
        
        output.tempAccessContacts
            .withLatestFrom(output.isInitialLoadingFinished) { ($0, $1) }
            .drive(
                onNext: { [weak self] args in
                    let (contacts, isInitialLoadingFinished) = args
                    
                    guard let self = self else {
                        return
                    }
                    
                    self.temporaryAccessView.viewModel.updateData(data: contacts)
                    
                    let newHeight = self.calculateAccessViewHeight(countItems: contacts.count)
                    self.tempAccessViewHeightConstraint.constant = newHeight
                    
                    UIView.animate(withDuration: isInitialLoadingFinished ? 0.25 : 0) { [weak self] in
                        self?.view.layoutIfNeeded()
                    }
                }
            )
            .disposed(by: disposeBag)
        
        output.isGrantedIntercomAccess
            .drive(
                onNext: { [weak self] isGranted in
                    self?.intercomAccessView.isAccessGranted = isGranted
                }
            )
            .disposed(by: disposeBag)
        
        output.temporaryIntercomCode
            .distinctUntilChanged()
            .drive(
                onNext: { [weak self] code in
                    self?.intercomAccessView.intercomCode = code
                    
                    UIView.animate(withDuration: 0.25) {
                        self?.view.layoutIfNeeded()
                    }
                }
            )
            .disposed(by: disposeBag)
        
        output.hasGates
            .distinctUntilChanged()
            .drive(
                onNext: { [weak self] hasGates in
                    self?.temporaryAccessContainer.isHidden = !hasGates
                    
                    UIView.animate(withDuration: 0.25) {
                        self?.view.layoutIfNeeded()
                    }
                }
            )
            .disposed(by: disposeBag)
        
        output.isFRSEnabled
            .drive(
                onNext: { [weak self] state in
                    guard let state = state  else {
                        self?.faceIdAccessView.isHidden = true
                        return
                    }
                    self?.faceIdAccessView.isAvailable = state
                    self?.faceIdAccessView.isHidden = false
                }
            )
            .disposed(by: disposeBag)
        
        output.isOwner
            .distinctUntilChanged()
            .drive(
                onNext: { [weak self] isOwner in
                    self?.permanentAccessContainer.isHidden = !isOwner
                    
                    UIView.animate(withDuration: 0.25) {
                        self?.view.layoutIfNeeded()
                    }
                }
            )
            .disposed(by: disposeBag)
        
        output.isInitialLoadingFinished
            .distinctUntilChanged()
            .isTrue()
            .delay(.milliseconds(500))
            .drive(
                onNext: { [weak self] _ in
                    self?.scrollView.isHidden = false
                    self?.skeletonView.hideSkeleton()
                    self?.skeletonView.isHidden = true
                }
            )
            .disposed(by: disposeBag)
    }

    private func calculateAccessViewHeight(countItems: Int) -> CGFloat {
        let addContactCellHeight = 57
        let contactCellHeight = 64
        
        return CGFloat(contactCellHeight * countItems + addContactCellHeight)
    }
    
}
