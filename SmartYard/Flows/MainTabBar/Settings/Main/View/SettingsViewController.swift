//
//  SettingsViewController.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import JGProgressHUD

class SettingsViewController: BaseViewController, LoaderPresentable {
    
    @IBOutlet private weak var fakeNavBar: FakeNavBar!
    @IBOutlet private weak var mainContainerView: UIView!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var skeletonContainer: UIView!
    
    private var dataSource: RxCollectionViewSectionedAnimatedDataSource<SettingsSectionModel>?
    
    private let refreshControl = UIRefreshControl()
    
    // MARK: Это костыль для того, чтобы понять, сколько на самом деле ячеек внутри секции
    // В методе configureCell у RxDataSource мы должны сконфигурировать ячейку
    // Но проблема в том, что RxDataSource выполняет операции обновления и добавления ячеек отдельно
    // Сначала выполняется обновление уже существующих ячеек, а потом добавляются новые
    // Поэтому на момент обновления ячеек мы не можем получить актуальное количество секций через dataSource[section]
    // Так что приходится проксировать количество ячеек в секциях в отдельный субъект и брать данные отсюда
    
    private let itemsCountProxy = BehaviorSubject<[Int: Int]>(value: [:])
    private let serviceButtonTapTrigger = PublishSubject<(SettingsDataItemIdentity, SettingsServiceType)>()
    
    private let addAddressTrigger = PublishSubject<Void>()
    
    private let viewModel: SettingsViewModel
    
    var loader: JGProgressHUD?
    
    init(viewModel: SettingsViewModel) {
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
        configureCollectionView()
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if skeletonContainer.sk.isSkeletonActive {
            skeletonContainer.showSkeletonAsynchronously()
        }
    }
    
    // swiftlint:disable:next function_body_length
    private func bind() {
        let itemSelected = collectionView.rx.itemSelected
            .map { [weak self] indexPath in
                self?.dataSource?[indexPath].identity
            }
            .ignoreNil()
        
        let input = SettingsViewModel.Input(
            backTrigger: fakeNavBar.rx.backButtonTap.asDriver(),
            itemSelected: itemSelected.asDriverOnErrorJustComplete(),
            serviceSelected: serviceButtonTapTrigger.asDriverOnErrorJustComplete(),
            updateDataTrigger: refreshControl.rx.controlEvent(.valueChanged).asDriverOnErrorJustComplete(),
            addAddressTrigger: addAddressTrigger.asDriverOnErrorJustComplete()
        )
        
        let output = viewModel.transform(input)
        
        // MARK: При получении моделей сначала проксируем словарь с количеством ячеек в секциях
        // А уже потом отправляем свежие модели в таблицу
        
        output.sectionModels
            .do(
                onNext: { [weak self] models in
                    let itemsCountDict: [Int: Int] = models.enumerated().reduce([:]) { dict, enumeration in
                        let (offset, element) = enumeration
                        
                        var mutableDict = dict
                        mutableDict[offset] = element.items.count
                        return mutableDict
                    }
                    
                    self?.itemsCountProxy.onNext(itemsCountDict)
                }
            )
            .drive(collectionView.rx.items(dataSource: dataSource!))
            .disposed(by: disposeBag)
        
        // MARK: Скроллим таблицу при сворачивании / разворачивании секций для лучшего UX
        
        let updateKindSubject = BehaviorSubject<SettingsSectionUpdateKind?>(value: nil)
        let updateKind = updateKindSubject.asDriver(onErrorJustReturn: nil)
        
        output.updateKind
            .drive(
                onNext: {
                    updateKindSubject.onNext($0)
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
        
        collectionView.rx
            .observeWeakly(CGSize.self, "contentSize", options: [.new])
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            
            // MARK: BatchUpdates проходят постепенно, поэтому contentSize меняется несколько раз
            // Чтобы анимации не конфликтовали, ждем, пока contentSize станет стабильным
            
            .debounce(.milliseconds(50))
            .withLatestFrom(updateKind)
            .ignoreNil()
            .do(
                onNext: { _ in
                    updateKindSubject.onNext(nil)
                }
            )
            .withLatestFrom(output.sectionModels) { ($0, $1) }
            
            // MARK: Ищем секцию, которая содержит Header с указанным идентификатором, и скроллим к нему
            
            .map { [weak self] updateKind, sectionModels -> (SettingsSectionUpdateKind, IndexPath)? in
                let neededSectionOffset = sectionModels.enumerated().first { _, model in
                    model.items.contains { $0.identity == updateKind.associatedIdentity }
                }?.offset
                
                guard let section = neededSectionOffset else {
                    return nil
                }
                
                guard !(self?.collectionView.refreshControl?.isRefreshing ?? false) else {
                    return nil
                }
                
                let indexPath = IndexPath(row: 0, section: section)
                return (updateKind, indexPath)
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] updateKind, indexPath in
                    self?.performScrollUpdate(updateKind: updateKind, to: indexPath)
                }
            )
            .disposed(by: disposeBag)
        
        output.shouldBlockInteraction
            .drive(
                onNext: { [weak self] shouldBlockInteraction in
                    self?.collectionView.isHidden = shouldBlockInteraction
                    self?.skeletonContainer.isHidden = !shouldBlockInteraction
                    
                    shouldBlockInteraction ?
                        self?.skeletonContainer.showSkeletonAsynchronously() :
                        self?.skeletonContainer.hideSkeleton()
                }
            )
            .disposed(by: disposeBag)
        /*
        output.clientName
            .drive(
                onNext: { [weak self] name in
                    self?.nameLabel.text = name
                }
            )
            .disposed(by: disposeBag)
        
        output.clientPhone
            .drive(
                onNext: { [weak self] phone in
                    self?.phoneNumberLabel.text = phone
                }
            )
            .disposed(by: disposeBag)
        */
        
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
    }
    
    private func performScrollUpdate(updateKind: SettingsSectionUpdateKind, to indexPath: IndexPath) {
        switch updateKind {
        case .expand:
            guard let attributes = collectionView.collectionViewLayout.layoutAttributesForItem(at: indexPath) else {
                return
            }
            
            let contentHeight = collectionView.collectionViewLayout.collectionViewContentSize.height
            
            let topInset = collectionView(
                collectionView,
                layout: collectionView.collectionViewLayout,
                insetForSectionAt: indexPath.section
            ).top
            
            let desiredOffset = attributes.frame.origin.y - topInset
            let maxPossibleOffset = contentHeight - collectionView.bounds.height
            
            let finalOffset = max(min(desiredOffset, maxPossibleOffset), 0)
            
            collectionView.setContentOffset(
                CGPoint(x: 0, y: finalOffset),
                animated: true
            )
            
        case .collapse:
            collectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
        }
    }
    
    private func configureView() {
        mainContainerView.cornerRadius = 24
        mainContainerView.layer.maskedCorners = .topCorners
    }
    
    private func configureCollectionView() {
        [
            SettingsControlPanelCell.self,
            SettingsActionCell.self,
            SettingsAddAddressCell.self
        ].forEach {
            collectionView.register(nibWithCellClass: $0)
        }
        
        collectionView.register(cellWithClass: SettingsHeaderCell.self)
        
        let dataSource = RxCollectionViewSectionedAnimatedDataSource<SettingsSectionModel>(
            configureCell: { [weak self] _, collectionView, indexPath, item in
                guard let self = self else {
                    // MARK: См. AddressesListViewController, почему нельзя просто вернуть UICollectionViewCell()
                    
                    return collectionView.dequeueReusableCell(withClass: SettingsHeaderCell.self, for: indexPath)
                }
                
                return self.configureCell(collectionView: collectionView, indexPath: indexPath, item: item)
            }
        )
        
        collectionView.rx
            .setDelegate(self)
            .disposed(by: disposeBag)
        
        self.dataSource = dataSource
        
        collectionView.refreshControl = refreshControl
        refreshControl.tintColor = UIColor.SmartYard.gray
    }
    
    // swiftlint:disable:next function_body_length
    private func configureCell(
        collectionView: UICollectionView,
        indexPath: IndexPath,
        item: SettingsDataItem
    ) -> UICollectionViewCell {
        // swiftlint:disable:next closure_body_length
        let cell: UICollectionViewCell = { [weak self] in
            guard let self = self else {
                return UICollectionViewCell()
            }
            
            switch item {
            case let .header(_, title, subtitle, isExpanded):
                let cell = collectionView.dequeueReusableCell(withClass: SettingsHeaderCell.self, for: indexPath)
                cell.configure(title: title, subtitle: subtitle, isExpanded: isExpanded)
                return cell
                
            case let .controlPanel(identity, configuration):
                let cell = collectionView.dequeueReusableCell(withClass: SettingsControlPanelCell.self, for: indexPath)
                cell.configure(with: configuration)
                
                let subject = PublishSubject<SettingsServiceType>()
                
                subject
                    .map { input -> (SettingsDataItemIdentity, SettingsServiceType) in
                        (identity, input)
                    }
                    .bind(to: self.serviceButtonTapTrigger)
                    .disposed(by: cell.disposeBag)
                
                cell.bind(with: subject)
                
                return cell
                
            case let .action(identity):
                let cell = collectionView.dequeueReusableCell(withClass: SettingsActionCell.self, for: indexPath)
                
                if case let .action(_, type) = identity {
                    cell.configure(title: type.localizedTitle)
                }
                
                return cell
                
            case .addAddress:
                let cell = collectionView.dequeueReusableCell(withClass: SettingsAddAddressCell.self, for: indexPath)
                
                let subject = PublishSubject<Void>()
                
                subject
                    .bind(to: addAddressTrigger)
                    .disposed(by: cell.disposeBag)
                
                cell.bind(with: subject)
                
                return cell
            }
        }()
        
        guard let itemsCountDict = try? itemsCountProxy.value(),
            let totalItemsInSection = itemsCountDict[indexPath.section] else {
            return cell
        }
        
        let isFirstInSection = indexPath.row == 0
        let isLastInSection = indexPath.row == totalItemsInSection - 1
        
        (cell as? CustomBorderCollectionViewCell)?.addCustomBorder(
            isFirstInSection: isFirstInSection,
            isLastInSection: isLastInSection,
            customBorderWidth: 1,
            customBorderColor: UIColor.SmartYard.grayBorder,
            customCornerRadius: 12,
            separatorInset: 24
        )
        
        return cell
    }

}

extension SettingsViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        guard let item = dataSource?[indexPath] else {
            return .zero
        }
        
        let height: CGFloat = {
            switch item {
            case let .header(_, address, contractName, _):
                return SettingsHeaderCell.preferredHeight(
                    for: UIScreen.main.bounds.width - 16 * 2,
                    title: address,
                    subtitle: contractName
                ).totalHeight
                
            default:
                return 80
            }
        }()
        
        return CGSize(width: collectionView.width - 32, height: height)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        return 0
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        return 0
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        let topInset: CGFloat = {
            switch section {
            case 0: return 16
            case collectionView.numberOfSections - 1: return 36
            default: return 10
            }
        }()
        
        let bottomInset: CGFloat = {
            switch section {
            case collectionView.numberOfSections - 1: return 20
            default: return 0
            }
        }()
        
        return UIEdgeInsets(top: topInset, left: 16, bottom: bottomInset, right: 16)
    }
    
}

