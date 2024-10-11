//
//  HomePayViewController.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 30.05.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import JGProgressHUD
import SkeletonView
import JTAppleCalendar

@objc protocol ContractCellProtocol {
    func didTapSettings(for cell: ContractViewCell)
    func didTapDetails(for cell: ContractViewCell)
    func didTapPayContract(for cell: ContractViewCell)
    func didTapParentControlInfo(for cell: ContractViewCell)
    func didTapParentControl(for cell: ContractViewCell)
    func didSetNewPosition(for cell: ContractViewCell)
    func didTapChangeRangeDetails(for cell: ContractViewCell)
    func didTapSendHistoryDetails(for cell: ContractViewCell)
    func didTapLimit(for cell: ContractViewCell)
}

class HomePayViewController: BaseViewController, LoaderPresentable {
    
    @IBOutlet private weak var skeletonContainer: UIView!
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var notificationButton: UIButton!
    @IBOutlet private weak var cityLocation: UILabel!
    @IBOutlet private weak var contractsView: UIView!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var pagerControl: UIPageControl!

    @IBOutlet weak var calendarBackView: UIView!
    @IBOutlet weak var calendarContainerView: UIView!
    @IBOutlet weak var calendarView: JTACMonthView!
    @IBOutlet weak var calendarRangeLabel: UILabel!
    @IBOutlet weak var calendarMonthLabel: UILabel!
    @IBOutlet weak var calendarYearLabel: UILabel!
    @IBOutlet weak var calendarLeftArrowButton: UIButton!
    @IBOutlet weak var calendarRightArrowButton: UIButton!

    private var refreshControl = UIRefreshControl()
    private let viewModel: HomePayViewModel
    private var contracts: [ContractFaceObject] = []
    let calendarRange = CalendarDateRange(
        period: 3,
        component: .year,
        to: Date()
    )
    var calendarRangeSelect: DetailRange?
    private var initialScrollDone: Bool = false
    
    let limitContractTrigger = PublishSubject<ContractFaceObject>()
    let settingsContractTrigger = PublishSubject<ContractFaceObject>()
    let detailsContractTrigger = PublishSubject<ContractFaceObject>()
    let paymentContractTrigger = PublishSubject<ContractFaceObject>()
    let parentInfoTrigger = PublishSubject<ContractFaceObject>()
    let parentStatusTrigger = PublishSubject<ContractFaceObject>()
    let calendarDetailsTrigger = PublishSubject<DetailRange?>()
    let sendDetailsTrigger = PublishSubject<DetailRange?>()

    var loader: JGProgressHUD?
    
    init(viewModel: HomePayViewModel) {
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
        configureCalendar()
        configureCollectionView()
        bind()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if !initialScrollDone {
            initialScrollDone = true
            if !contracts.isEmpty {
                cityLocation.text = contracts.first!.cityName
            }
            if contracts.count > 1 {
                pagerControl.currentPage = 0
                pagerControl.numberOfPages = contracts.count
                let indexPath = IndexPath(row: 0, section: 1)
                collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !initialScrollDone {
            initialScrollDone = true
            if !contracts.isEmpty {
                cityLocation.text = contracts.first!.cityName
            }
            if contracts.count > 1 {
                pagerControl.currentPage = 0
                pagerControl.numberOfPages = contracts.count
                let indexPath = IndexPath(row: 0, section: 1)
                collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if skeletonContainer.sk.isSkeletonActive {
            skeletonContainer.showSkeletonAsynchronously()
        }
    }
    
    private func configureView() {
        scrollView.refreshControl = refreshControl
        pagerControl.addTarget(self, action: #selector(pageDidChange(sender:)), for: .valueChanged)
        pagerControl.isHidden = true
        
        subscribeToBadgeUpdates()
    }
    
    @objc func pageDidChange(sender: UIPageControl) {
        let indexPath = IndexPath(row: pagerControl.currentPage, section: 1)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }

    private func configureCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.register(nibWithCellClass: ContractViewCell.self)
    }
    
    private func bind() {
        
        calendarDetailsTrigger
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .drive(
                onNext: { range in
                    let contract = range.contract
                    
                    guard let fromDay = range.fromDay, let toDay = range.toDay else {
                        return
                    }
                    self.contracts[contract.number - 1].details.fromDay = fromDay
                    self.contracts[contract.number - 1].details.toDay = toDay
                    self.contracts[contract.number - 1].details.details = []

                    let indexPath = IndexPath(row: contract.number - 1, section: (self.contracts.count > 1 ? 1 : 0))
                    guard let cell = self.collectionView.cellForItem(at: indexPath) as? ContractViewCell else {
                        return
                    }

                    cell.updateDetails(details: self.contracts[contract.number - 1].details)
                }
            )
            .disposed(by: disposeBag)
        
        let input = HomePayViewModel.Input(
            refreshDataTrigger: refreshControl.rx.controlEvent(.valueChanged).asDriver(),
            notificationTrigger: notificationButton.rx.tap.asDriverOnErrorJustComplete(),
            limitTrigger: limitContractTrigger.asDriverOnErrorJustComplete(),
            settingsTrigger: settingsContractTrigger.asDriverOnErrorJustComplete(),
            detailsTrigger: detailsContractTrigger.asDriverOnErrorJustComplete(),
            paymentTrigger: paymentContractTrigger.asDriverOnErrorJustComplete(),
            parentInfoTrigger: parentInfoTrigger.asDriverOnErrorJustComplete(),
            parentStatusTrigger: parentStatusTrigger.asDriverOnErrorJustComplete(),
            calendarDetailsTrigger: calendarDetailsTrigger.asDriver(onErrorJustReturn: nil),
            sendDetailsTrigger: sendDetailsTrigger.asDriver(onErrorJustReturn: nil)
        )
        
        let output = viewModel.transform(input)
        
        output.contracts
            .drive(
                onNext: { [weak self] contracts in
                    guard let self = self else {
                        return
                    }
                    self.setContracts(contracts)
                }
            )
            .disposed(by: disposeBag)
        
        output.reloadingFinished
            .drive(
                onNext: { [weak self] in
                    self?.refreshControl.endRefreshing()
                }
            )
            .disposed(by: disposeBag)
        
        output.parentStatus
            .drive(
                onNext: { [weak self] args in
                    let (number, status) = args
                    
                    guard let self = self else {
                        return
                    }
                    
                    let indexPath = IndexPath(row: number - 1, section: (self.contracts.count > 1 ? 1 : 0))
                    guard let cell = self.collectionView.cellForItem(at: indexPath) as? ContractViewCell else {
                        return
                    }
                    self.contracts[number - 1].parentStatus = status
                    cell.updateParentStatus(status: status)
                }
            )
            .disposed(by: disposeBag)
        
        output.details
            .drive(
                onNext: { [weak self] args in
                    let (contract, details) = args
                    
                    guard let self = self else {
                        return
                    }
                    
                    let indexPath = IndexPath(row: contract.number - 1, section: (self.contracts.count > 1 ? 1 : 0))
                    guard let cell = self.collectionView.cellForItem(at: indexPath) as? ContractViewCell else {
                        return
                    }
                    self.contracts[contract.number - 1].details.fromDay = contract.details.fromDay
                    self.contracts[contract.number - 1].details.toDay = contract.details.toDay
                    self.contracts[contract.number - 1].details.details = details
                    cell.updateDetails(details: self.contracts[contract.number - 1].details)
                }
            )
            .disposed(by: disposeBag)
        
        output.shouldBlockInteraction
            .drive(
                onNext: { [weak self] shouldBlockInteraction in
                    self?.skeletonContainer.isHidden = !shouldBlockInteraction
                    
                    if shouldBlockInteraction {
                        self?.skeletonContainer.showSkeletonAsynchronously()
                    } else {
                        self?.skeletonContainer.hideSkeleton()
                    }
                }
            )
            .disposed(by: disposeBag)
        
   }
    
    private func updateNotificationsButton(shouldShowBadge: Bool) {
        notificationButton.tintColor = shouldShowBadge ? UIColor.SmartYard.blue : UIColor.lightGray
    }
    
    private func subscribeToBadgeUpdates() {
        NotificationCenter.default.rx
            .notification(.unreadInboxMessagesAvailable)
            .asDriverOnErrorJustComplete()
            .drive(
                onNext: { [weak self] _ in
                    self?.updateNotificationsButton(shouldShowBadge: true)
                }
            )
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx
            .notification(.allInboxMessagesRead)
            .asDriverOnErrorJustComplete()
            .drive(
                onNext: { [weak self] _ in
                    self?.updateNotificationsButton(shouldShowBadge: false)
                }
            )
            .disposed(by: disposeBag)
    }

    func setContracts(_ contracts: [ContractFaceObject]) {
        self.contracts = contracts
        pagerControl.isHidden = contracts.count < 2
        initialScrollDone = false
        collectionView.reloadData()
        collectionView.layoutIfNeeded()
    }
    
}

extension HomePayViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard !contracts.isEmpty else {
            return 1
        }
        
        if contracts.count == 1 {
            return 1
        }

        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard !contracts.isEmpty else {
            return 0
        }
        if contracts.count == 1 {
            return 1
        }
        switch (section){
        case 1:
            return contracts.count
        default:
            return 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withClass: ContractViewCell.self, for: indexPath)

        guard contracts.count > 1 else {
            cell.configureCell(contracts[0])
            cell.delegate = self
            return cell
        }
        
        switch (indexPath.section){
        case 0:
            cell.configureCell(contracts.last!)
        case 2:
            cell.configureCell(contracts.first!)
        default:
            cell.configureCell(contracts[indexPath.row])
        }
        
        cell.delegate = self
        return cell
    }
    
}

extension HomePayViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let width = UIScreen.main.bounds.width - 40
        return CGSize(width: width, height: 524)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard contracts.count > 1 else {
            return
        }
        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        if let indexPath = collectionView.indexPathForItem(at: visiblePoint) {
            if let cell = collectionView.cellForItem(at: indexPath) as? ContractViewCell {
                cityLocation.text = cell.contract?.cityName
            }
            switch indexPath.section {
            case 0:
                let index = IndexPath(row: contracts.count - 1, section: 1)
                collectionView.scrollToItem(at: index, at: .centeredHorizontally, animated: false)
                pagerControl.currentPage = contracts.count - 1
            case 2:
                let index = IndexPath(row: 0, section: 1)
                collectionView.scrollToItem(at: index, at: .centeredHorizontally, animated: false)
                pagerControl.currentPage = 0
            default:
                pagerControl.currentPage = indexPath.row
                break
            }
        }
    }
}

extension HomePayViewController: ContractCellProtocol {
    func didTapChangeRangeDetails(for cell: ContractViewCell) {
        guard let contract = cell.contract else {
            return
        }
        showCalendar(contract: contract, from: contract.details.fromDay, to: contract.details.toDay)
    }
    
    func didTapSendHistoryDetails(for cell: ContractViewCell) {
        guard let contract = cell.contract else {
            return
        }
        let range = DetailRange(contract: contract, fromDay: contract.details.fromDay, toDay: contract.details.toDay)
        
        sendDetailsTrigger.onNext(range)
    }
    
    func didSetNewPosition(for cell: ContractViewCell) {
        guard let contract = cell.contract else {
            return
        }
        self.contracts[contract.number - 1].position = contract.position
    }
    
    func didTapParentControlInfo(for cell: ContractViewCell) {
        guard let contract = cell.contract, contract.services[.internet] == true else {
            return
        }
        parentInfoTrigger.onNext(contract)
    }
    
    func didTapParentControl(for cell: ContractViewCell) {
        guard let contract = cell.contract, contract.services[.internet] == true else {
            return
        }
        parentStatusTrigger.onNext(contract)
    }
    
    func didTapSettings(for cell: ContractViewCell) {
        guard let contract = cell.contract else {
            return
        }
        settingsContractTrigger.onNext(contract)
    }
    
    func didTapDetails(for cell: ContractViewCell) {
        guard let contract = cell.contract else {
            return
        }
        detailsContractTrigger.onNext(contract)
    }
    
    func didTapPayContract(for cell: ContractViewCell) {
        guard let contract = cell.contract else {
            return
        }
        paymentContractTrigger.onNext(contract)
    }
    
    func didTapLimit(for cell: ContractViewCell) {
        guard let contract = cell.contract else {
            return
        }
        limitContractTrigger.onNext(contract)
    }
}
