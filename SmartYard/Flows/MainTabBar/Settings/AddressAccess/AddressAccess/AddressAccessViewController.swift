//
//  AddressAccessViewController.swift
//  SmartYard
//
//  Created by Mad Brains on 14.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import JGProgressHUD

final class AddressAccessViewController: BaseViewController, LoaderPresentable {
    
    // MARK: - Outlets

    @IBOutlet private weak var fakeNavBar: FakeNavBar!
    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var addressView: FullRoundedView!
    @IBOutlet private weak var intercomAccessView: IntercomTemporaryAccessView!
    @IBOutlet private weak var faceIdAccessView: FaceIdAccessView!
    
    @IBOutlet private weak var addressPermanentAccessContainer: UIView!
    @IBOutlet private weak var addressPermanentAccessView: AccessView!
    
    @IBOutlet private weak var gateAccessContainer: UIView!
    @IBOutlet private weak var gateAccessAddButton: UIButton!
    @IBOutlet private weak var gateAccessView: GateAccessView!

    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var skeletonView: AddressAccessSkeletonView!
    
    private var permanentAccessViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet private var stackViewTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var gateAccessTitleLabel: UILabel!
    @IBOutlet private weak var permanentAccessTitleLabel: UILabel!
    @IBOutlet private weak var addressAccessTitleLabel: UILabel!
    // MARK: - Properties
    
    var loader: JGProgressHUD?
    
    private let viewModel: AddressAccessViewModel
    
    // MARK: - Lifecycle
    
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
        configureUI()
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if skeletonView.sk.isSkeletonActive {
            skeletonView.showSkeletonAsynchronously(with: UIColor.SmartYard.secondBackgroundColor)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        /// 24 px = это то, насколько addressView выступает над scrollView
        /// 16 px - это отступ между addressView и следующей за ней вьюхой
        let neededInset = addressView.bounds.height - 24 + 16
        
        stackViewTopConstraint.constant = neededInset
    }
    
    // MARK: - Configuration
    private func configureUI() {
        gateAccessTitleLabel.text = L10n.Settings.AddressAccess.accessToTheBarrierGate
        gateAccessAddButton.setTitle(L10n.Common.add, for: .normal)
        permanentAccessTitleLabel.text = L10n.Settings.AddressAccess.permanentAccessTitle
        addressLabel.text = L10n.Settings.AddressAccess.addressPlaceholder
        addressAccessTitleLabel.text = L10n.Settings.AddressAccess.accessToAddress
        let permanentViewHeight = addressPermanentAccessView.heightAnchor.constraint(equalToConstant: 57)
        permanentViewHeight.isActive = true
        permanentAccessViewHeightConstraint = permanentViewHeight
        gateAccessAddButton.setTitleForAllStates(L10n.Common.add)
        gateAccessView.translatesAutoresizingMaskIntoConstraints = false
        addressPermanentAccessView.translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.isHidden = true
        skeletonView.isHidden = false
        skeletonView.showSkeletonAsynchronously(with: UIColor.SmartYard.secondBackgroundColor)
    }
    
    private func calculateAccessViewHeight(countItems: Int) -> CGFloat {
        let addContactCellHeight = 57
        let contactCellHeight = 64
        
        return CGFloat(contactCellHeight * countItems + addContactCellHeight)
    }
    
    // MARK: - Bindings
    
    // swiftlint:disable:next function_body_length
    private func bind() {
        let segmentControlValueChangedSubject = BehaviorRelay<GateAccessSegmentType?>(value: nil)
        gateAccessView.segmentControlValueChangedRelay
            .distinctUntilChanged()
            .debounce(.milliseconds(50), scheduler: MainScheduler.instance)
            .bind(to: segmentControlValueChangedSubject)
            .disposed(by: disposeBag)
        
        let input = AddressAccessViewModel.Input(
            viewDidAppearTrigger: rx.viewWillAppear.asDriverOnErrorJustComplete(),
            refreshIntercomTempCodeTrigger: intercomAccessView.rx.refreshButtonTapped.asDriverOnErrorJustComplete(),
            openGuestAccessTrigger: intercomAccessView.rx.openButtonTapped.asDriverOnErrorJustComplete(),
            waitingGuestsHintTrigger: intercomAccessView.rx.waitingGuestsQuestionMarkTapped.asDriverOnErrorJustComplete(),
            configureFaces: faceIdAccessView.rx.configureButtonTapped.asDriverOnErrorJustComplete(),
            segmentControlTrigger: segmentControlValueChangedSubject.asDriver(onErrorJustReturn: nil),
            smsToPermanentContactTrigger: addressPermanentAccessView.sendSmsSubject.asDriverOnErrorJustComplete(),
            smsToGateAccessContactTrigger: gateAccessView.sendSMSToPersonTappedRelay.asDriverOnErrorJustComplete(),
            deletePermanentContactTrigger: addressPermanentAccessView.deletePressedSubject.asDriverOnErrorJustComplete(),
            deleteGateAccessContactTrigger: gateAccessView.deleteGateAccessPersonRelay.asDriverOnErrorJustComplete(),
            deleteGateAccessLicensePlateTrigger: gateAccessView.deleteGateAccessCarRelay.asDriverOnErrorJustComplete(),
            addNewPermanentContact: addressPermanentAccessView.addNewPersonSubject.asDriverOnErrorJustComplete(),
            addNewGateAccessContact: gateAccessAddButton.rx.tap.asDriverOnErrorJustComplete(),
            addNewGateAccessLicensePlate: gateAccessAddButton.rx.tap.asDriverOnErrorJustComplete(),
            goToGateAccessDetail: gateAccessView.goToGateAccessDetailRelay.asDriverOnErrorJustComplete(),
            backTrigger: fakeNavBar.rx.backButtonTap.asDriver()
        )
        
        let output = viewModel.transform(input: input)
        
        // MARK: - Outputs
        
        output.isLoading
            .debounce(.milliseconds(25))
            .drive { [weak self] isLoading in
                if isLoading {
                    self?.view.endEditing(true)
                }
                
                self?.updateLoader(isEnabled: isLoading, detailText: nil)
            }
            .disposed(by: disposeBag)
        
        output.objectAddress
            .drive { [weak self] address in
                self?.addressLabel.text = address
            }
            .disposed(by: disposeBag)
        
        output.permanentAccessContacts
            .withLatestFrom(output.isInitialLoadingFinished) { ($0, $1) }
            .drive { [weak self] args in
                let (contacts, isInitialLoadingFinished) = args
                
                guard let self = self else {
                    return
                }
                
                self.addressPermanentAccessView.viewModel.updateData(data: contacts)
                
                let newHeight = self.calculateAccessViewHeight(countItems: contacts.count)
                self.permanentAccessViewHeightConstraint.constant = newHeight
                
                UIView.animate(withDuration: isInitialLoadingFinished ? 0.25 : 0) { [weak self] in
                    self?.view.layoutIfNeeded()
                }
            }
            .disposed(by: disposeBag)
        
        output.isGrantedIntercomAccess
            .drive {  [weak self] isGranted in
                self?.intercomAccessView.isAccessGranted = isGranted
            }
            .disposed(by: disposeBag)
        
        output.temporaryIntercomCode
            .distinctUntilChanged()
            .drive { [weak self] code in
                self?.intercomAccessView.intercomCode = code
            }
            .disposed(by: disposeBag)
        
        Driver
            .combineLatest(output.hasGates, output.isLPRSEnabled)
            .map { hasGates, isLPRSEnabled in
                hasGates || isLPRSEnabled
            }
            .distinctUntilChanged()
            .drive { [weak self] isAvailable in
                self?.gateAccessContainer.isHidden = !isAvailable
            }
            .disposed(by: disposeBag)
        
        output.isFRSEnabled
            .drive { [weak self] state in
                self?.faceIdAccessView.isAvailable = state
                self?.faceIdAccessView.isHidden = !state
            }
            .disposed(by: disposeBag)
        
        output.isLPRSEnabled
            .drive { [weak self] state in
                self?.gateAccessView.segmentControl(isHidden: !state)
            }
            .disposed(by: disposeBag)
        
        Driver
            .combineLatest(
                output.gateAccessSelectedSegmentControlType.distinctUntilChanged(),
                output.gateAccessLicensePlates,
                output.gateAccessContacts
            )
            .drive { [weak self] selectedType, licensePlates, contacts in
                let selectedIndex = selectedType == .cars ? 0 : 1
                self?.gateAccessView.segmentControl(selectedSegmentIndex: selectedIndex)
                
                switch selectedType {
                case .cars:
                    self?.gateAccessView.viewModel.update(carData: licensePlates)
                case .persons:
                    self?.gateAccessView.viewModel.update(personData: contacts)
                case .none:
                    break
                }
            }
            .disposed(by: disposeBag)
        
        output.isOwner
            .distinctUntilChanged()
            .drive { [weak self] isOwner in
                self?.addressPermanentAccessContainer.isHidden = !isOwner
            }
            .disposed(by: disposeBag)
        
        output.isInitialLoadingFinished
            .distinctUntilChanged()
            .isTrue()
            .delay(.milliseconds(500))
            .drive { [weak self] _ in
                self?.scrollView.isHidden = false
                self?.skeletonView.hideSkeleton()
                self?.skeletonView.isHidden = true
            }
            .disposed(by: disposeBag)
    }
    
}
